// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts//contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts//contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts//contracts/utils/Pausable.sol";
import "./RuneStone.sol";
import "./GameItems.sol";

contract RuneCrusher is Ownable, ReentrancyGuard, Pausable {
    // Contract references
    RuneStonesOfPower public immutable runeStones;
    GameItems public immutable gameItems;
    
    // Fee configuration
    uint256 public crushingFee; // Fee in wei per crushing operation
    address public feeCollector;
    
    // Cooldown system
    mapping(address => uint256) public lastCrushTime;
    uint256 public crushCooldown = 1 hours; // Default 1 hour cooldown
    
    // Events
    event ItemsCrushed(
        address indexed player,
        uint256 indexed itemId,
        uint256 itemAmount,
        uint256[] runeIds,
        uint256[] runeAmounts
    );
    event CrushingFeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newCollector);
    event CooldownUpdated(uint256 newCooldown);
    event FeesCollected(address collector, uint256 amount);
    
    constructor(
        address _runeStones,
        address _gameItems,
        address _feeCollector,
        uint256 _crushingFee
    ) Ownable(msg.sender) {
        require(_runeStones != address(0), "RuneCrusher: Invalid rune stones address");
        require(_gameItems != address(0), "RuneCrusher: Invalid game items address");
        require(_feeCollector != address(0), "RuneCrusher: Invalid fee collector address");
        
        runeStones = RuneStonesOfPower(_runeStones);
        gameItems = GameItems(_gameItems);
        feeCollector = _feeCollector;
        crushingFee = _crushingFee;
    }

    // Admin functions
    function setFee(uint256 newFee) external onlyOwner {
        crushingFee = newFee;
        emit CrushingFeeUpdated(newFee);
    }
    
    function setFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "RuneCrusher: Invalid fee collector address");
        feeCollector = newCollector;
        emit FeeCollectorUpdated(newCollector);
    }
    
    function setCooldown(uint256 newCooldown) external onlyOwner {
        crushCooldown = newCooldown;
        emit CooldownUpdated(newCooldown);
    }
    
    function collectFees() external {
        require(msg.sender == feeCollector, "RuneCrusher: Not fee collector");
        uint256 balance = address(this).balance;
        require(balance > 0, "RuneCrusher: No fees to collect");
        
        (bool success, ) = feeCollector.call{value: balance}("");
        require(success, "RuneCrusher: Fee transfer failed");
        
        emit FeesCollected(feeCollector, balance);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }

    // Main crushing function
    function crushItems(uint256 itemId, uint256 amount) 
        external 
        payable
        nonReentrant
        whenNotPaused
    {
        // Check cooldown
        require(
            block.timestamp >= lastCrushTime[msg.sender] + crushCooldown,
            "RuneCrusher: Crushing on cooldown"
        );
        
        // Check fee
        require(msg.value >= crushingFee, "RuneCrusher: Insufficient fee");
        
        // Get crushing result
        (uint256[] memory runeIds, uint256[] memory runeAmounts) = 
            gameItems.getCrushingResult(itemId);
            
        require(runeIds.length > 0, "RuneCrusher: Item cannot be crushed");
        
        // Crush the items and receive runes
        (uint256[] memory resultRuneIds, uint256[] memory resultAmounts) = 
            gameItems.crush(msg.sender, itemId, amount);
            
        // Mint runes to the player
        for (uint256 i = 0; i < resultRuneIds.length; i++) {
            runeStones.mint(msg.sender, resultRuneIds[i], resultAmounts[i], "");
        }
        
        // Update cooldown
        lastCrushTime[msg.sender] = block.timestamp;
        
        emit ItemsCrushed(
            msg.sender,
            itemId,
            amount,
            resultRuneIds,
            resultAmounts
        );
        
        // Return excess fee if any
        uint256 excess = msg.value - crushingFee;
        if (excess > 0) {
            (bool success, ) = msg.sender.call{value: excess}("");
            require(success, "RuneCrusher: Failed to return excess fee");
        }
    }

    // Batch crushing function
    function crushItemsBatch(
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) 
        external 
        payable
        nonReentrant
        whenNotPaused
    {
        require(
            itemIds.length == amounts.length,
            "RuneCrusher: Array lengths must match"
        );
        
        require(
            msg.value >= crushingFee * itemIds.length,
            "RuneCrusher: Insufficient fee"
        );
        
        require(
            block.timestamp >= lastCrushTime[msg.sender] + crushCooldown,
            "RuneCrusher: Crushing on cooldown"
        );
        
        for (uint256 i = 0; i < itemIds.length; i++) {
            (uint256[] memory runeIds, uint256[] memory runeAmounts) = 
                gameItems.crush(msg.sender, itemIds[i], amounts[i]);
                
            // Mint runes to the player
            for (uint256 j = 0; j < runeIds.length; j++) {
                runeStones.mint(msg.sender, runeIds[j], runeAmounts[j], "");
            }
            
            emit ItemsCrushed(
                msg.sender,
                itemIds[i],
                amounts[i],
                runeIds,
                runeAmounts
            );
        }
        
        // Update cooldown
        lastCrushTime[msg.sender] = block.timestamp;
        
        // Return excess fee if any
        uint256 totalFee = crushingFee * itemIds.length;
        uint256 excess = msg.value - totalFee;
        if (excess > 0) {
            (bool success, ) = msg.sender.call{value: excess}("");
            require(success, "RuneCrusher: Failed to return excess fee");
        }
    }

    // View functions
    function canCrush(address player) external view returns (bool) {
        return block.timestamp >= lastCrushTime[player] + crushCooldown;
    }
    
    function getTimeUntilNextCrush(address player) external view returns (uint256) {
        uint256 nextCrushTime = lastCrushTime[player] + crushCooldown;
        if (block.timestamp >= nextCrushTime) return 0;
        return nextCrushTime - block.timestamp;
    }
    
    // Required to receive ETH
    receive() external payable {}
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RuneCrusher.sol";
import "../src/RuneStone.sol";
import "../src/GameItems.sol";

contract RuneCrusherTest is Test {
    RuneCrusher public runeCrusher;
    RuneStonesOfPower public runeStones;
    GameItems public gameItems;
    
    address public owner;
    address public feeCollector;
    address public player;
    
    uint256 public constant CRUSHING_FEE = 0.01 ether;

    function setUp() public {
        owner = address(this);
        feeCollector = makeAddr("feeCollector");
        player = makeAddr("player");

        // Deploy contracts
        runeStones = new RuneStonesOfPower();
        gameItems = new GameItems();
        runeCrusher = new RuneCrusher(
            address(runeStones),
            address(gameItems),
            feeCollector,
            CRUSHING_FEE
        );

        // Setup permissions
        runeStones.setMinter(address(runeCrusher), true);
        gameItems.setCrusher(address(runeCrusher), true);

        // Create a test item and rune
        gameItems.createItem(1, "Test Item", GameItems.ItemType.WEAPON, GameItems.Rarity.COMMON, 1, new uint256[](1), new uint256[](1));
        gameItems.createItem[1] = 1;
        gameItems.createItem[1] = 100;
        runeStones.createRuneStone(1, "Test Rune", 10, 0);

        // Mint some items to the player
        vm.prank(owner);
        gameItems.mint(player, 1, 10, "");
    }

    function testCrushItems() public {
        vm.startPrank(player);
        vm.deal(player, 1 ether);

        // Approve RuneCrusher to spend player's items
        gameItems.setApprovalForAll(address(runeCrusher), true);

        // Crush items
        runeCrusher.crushItems{value: CRUSHING_FEE}(1, 1);

        // Check results
        assertEq(gameItems.balanceOf(player, 1), 9);
        assertEq(runeStones.balanceOf(player, 1), 100);

        vm.stopPrank();
    }

    function testFailInsufficientFee() public {
        vm.prank(player);
        vm.expectRevert("RuneCrusher: Insufficient fee");
        runeCrusher.crushItems{value: CRUSHING_FEE - 1 wei}(1, 1);
    }

    function testFailCrushOnCooldown() public {
        vm.startPrank(player);
        vm.deal(player, 2 ether);

        gameItems.setApprovalForAll(address(runeCrusher), true);

        // First crush
        runeCrusher.crushItems{value: CRUSHING_FEE}(1, 1);

        // Attempt to crush again immediately
        vm.expectRevert("RuneCrusher: Crushing on cooldown");
        runeCrusher.crushItems{value: CRUSHING_FEE}(1, 1);

        vm.stopPrank();
    }

    function testCollectFees() public {
        // Perform a crush to generate fees
        vm.startPrank(player);
        vm.deal(player, 1 ether);
        gameItems.setApprovalForAll(address(runeCrusher), true);
        runeCrusher.crushItems{value: CRUSHING_FEE}(1, 1);
        vm.stopPrank();

        // Collect fees
        uint256 initialBalance = feeCollector.balance;
        vm.prank(feeCollector);
        runeCrusher.collectFees();

        assertEq(feeCollector.balance - initialBalance, CRUSHING_FEE);
    }

    function testSetFee() public {
        uint256 newFee = 0.02 ether;
        runeCrusher.setFee(newFee);
        assertEq(runeCrusher.crushingFee(), newFee);
    }

    function testSetFeeCollector() public {
        address newCollector = makeAddr("newCollector");
        runeCrusher.setFeeCollector(newCollector);
        assertEq(runeCrusher.feeCollector(), newCollector);
    }

    function testSetCooldown() public {
        uint256 newCooldown = 2 hours;
        runeCrusher.setCooldown(newCooldown);
        assertEq(runeCrusher.crushCooldown(), newCooldown);
    }

    function testPauseAndUnpause() public {
        runeCrusher.pause();
        assertTrue(runeCrusher.paused());

        vm.expectRevert("Pausable: paused");
        vm.prank(player);
        runeCrusher.crushItems{value: CRUSHING_FEE}(1, 1);

        runeCrusher.unpause();
        assertFalse(runeCrusher.paused());
    }
}

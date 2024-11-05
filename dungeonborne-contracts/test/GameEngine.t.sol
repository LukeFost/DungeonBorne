// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/GameEngine.sol";
import "../src/RuneStone.sol";
import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract GameEngineTest is Test, ERC1155Holder {
    GameEngine public gameEngine;
    RuneStone public runeStone;
    VRFCoordinatorV2Mock public vrfCoordinator;
    
    address public owner;
    address public player;
    
    // Test data
    uint256 public constant INITIAL_MONSTER_ID = 1;
    uint8 public constant INITIAL_HP = 100;
    uint8 public constant INITIAL_AC = 15;
    uint16 public constant INITIAL_X = 10;
    uint16 public constant INITIAL_Y = 20;
    uint16 public constant INITIAL_FACING = 90;
    
    // VRF configuration
    uint96 public constant LINK_AMOUNT = 1 ether;
    uint32 public constant CALLBACK_GAS_LIMIT = 100000;
    uint64 public constant SUBSCRIPTION_ID = 1;
    
    event MonsterSpawned(uint256 indexed monsterId, uint16 x, uint16 y, uint16 facing);
    event MonsterDefeated(uint256 indexed monsterId);
    event CombatResult(uint256 indexed monsterId, address indexed player, uint8 damage, bool hit);
    
    function setUp() public {
        owner = address(this);
        player = makeAddr("player");
        
        // Setup LINK token and VRF Coordinator mock
        vrfCoordinator = new VRFCoordinatorV2Mock(0.1 ether, 1e9);
        
        // Create VRF subscription
        vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(SUBSCRIPTION_ID, LINK_AMOUNT);
        
        // Deploy RuneStone
        runeStone = new RuneStone(owner);
        
        // Deploy GameEngine
        gameEngine = new GameEngine(
            address(runeStone),
            address(0), // LINK token not needed with mock
            address(vrfCoordinator)
        );
        
        // Add consumer to VRF subscription
        vrfCoordinator.addConsumer(SUBSCRIPTION_ID, address(gameEngine));
        
        // Setup player as ERC1155 receiver
        vm.deal(player, 100 ether);
        MockERC1155Receiver mockReceiver = new MockERC1155Receiver();
        vm.etch(player, address(mockReceiver).code);

        // Approve GameEngine to burn RuneStones
        vm.startPrank(player);
        runeStone.setApprovalForAll(address(gameEngine), true);
        vm.stopPrank();
    }
    
    function test_SpawnMonster() public {
        uint8[6] memory stats = [10, 12, 14, 8, 10, 8]; // STR, DEX, CON, INT, WIS, CHA
        
        vm.expectEmit(true, true, true, true);
        emit MonsterSpawned(INITIAL_MONSTER_ID, INITIAL_X, INITIAL_Y, INITIAL_FACING);
        
        gameEngine.spawnMonster(
            INITIAL_MONSTER_ID,
            INITIAL_HP,
            INITIAL_AC,
            stats,
            INITIAL_X,
            INITIAL_Y,
            INITIAL_FACING
        );
        
        IGameEngine.Monster memory monster = gameEngine.getMonster(INITIAL_MONSTER_ID);
        
        assertEq(monster.hp, INITIAL_HP);
        assertEq(monster.ac, INITIAL_AC);
        assertEq(monster.str, stats[0]);
        assertEq(monster.dex, stats[1]);
        assertEq(monster.con, stats[2]);
        assertEq(monster.smt, stats[3]);
        assertEq(monster.wis, stats[4]);
        assertEq(monster.cha, stats[5]);
        assertEq(monster.xPos, INITIAL_X);
        assertEq(monster.yPos, INITIAL_Y);
        assertEq(monster.facing, INITIAL_FACING);
        assertTrue(monster.isActive);
    }

    function test_Attack() public {
        // Spawn monster
        uint8[6] memory stats = [10, 12, 14, 8, 10, 8];
        gameEngine.spawnMonster(
            INITIAL_MONSTER_ID,
            INITIAL_HP,
            INITIAL_AC,
            stats,
            INITIAL_X,
            INITIAL_Y,
            INITIAL_FACING
        );
        
        // Mint RuneStone for player
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        // Attack monster as player
        vm.prank(player);
        gameEngine.attack(INITIAL_MONSTER_ID, tokenId);

        // Process VRF callback
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 12345;
        vrfCoordinator.fulfillRandomWordsWithOverride(1, address(gameEngine), randomWords);
        
        // Get monster state after attack
        IGameEngine.Monster memory monster = gameEngine.getMonster(INITIAL_MONSTER_ID);
        assertEq(monster.hp, INITIAL_HP - 10); // Basic attack does 10 damage in MVP
    }
    
    function test_MonsterDefeat() public {
        // Spawn monster with low HP
        uint8[6] memory stats = [10, 12, 14, 8, 10, 8];
        gameEngine.spawnMonster(
            INITIAL_MONSTER_ID,
            5, // Low HP
            INITIAL_AC,
            stats,
            INITIAL_X,
            INITIAL_Y,
            INITIAL_FACING
        );
        
        // Mint RuneStone for player
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        vm.prank(player);
        gameEngine.attack(INITIAL_MONSTER_ID, tokenId);

        // Process VRF callback and expect MonsterDefeated event
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 12345;

        vm.expectEmit(true, false, false, false);
        emit MonsterDefeated(INITIAL_MONSTER_ID);
        vrfCoordinator.fulfillRandomWordsWithOverride(1, address(gameEngine), randomWords);
        
        // Verify monster is defeated
        vm.expectRevert("GameEngine: Monster not active");
        gameEngine.getMonster(INITIAL_MONSTER_ID);
    }
    
    function test_RevertAttackInactiveMonster() public {
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        vm.prank(player);
        vm.expectRevert("GameEngine: Monster not active");
        gameEngine.attack(999, tokenId); // Non-existent monster ID
    }
    
    function test_RevertSpawnMonsterInvalidFacing() public {
        uint8[6] memory stats = [10, 12, 14, 8, 10, 8];
        
        vm.expectRevert("GameEngine: Invalid facing direction");
        gameEngine.spawnMonster(
            INITIAL_MONSTER_ID,
            INITIAL_HP,
            INITIAL_AC,
            stats,
            INITIAL_X,
            INITIAL_Y,
            360 // Invalid facing (must be 0-359)
        );
    }
    
    function test_VRFCallback() public {
        // Spawn monster
        uint8[6] memory stats = [10, 12, 14, 8, 10, 8];
        gameEngine.spawnMonster(
            INITIAL_MONSTER_ID,
            INITIAL_HP,
            INITIAL_AC,
            stats,
            INITIAL_X,
            INITIAL_Y,
            INITIAL_FACING
        );
        
        // Mint RuneStone for player
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        // Attack monster as player
        vm.prank(player);
        gameEngine.attack(INITIAL_MONSTER_ID, tokenId);
        
        // Generate and fulfill random number
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 12345;
        
        vm.expectEmit(true, true, false, true);
        emit CombatResult(INITIAL_MONSTER_ID, player, 10, true);
        
        vrfCoordinator.fulfillRandomWordsWithOverride(1, address(gameEngine), randomWords);
    }
}

contract MockERC1155Receiver is ERC1155Holder {}

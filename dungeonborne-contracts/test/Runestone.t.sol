// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RuneStone.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MockERC1155Receiver is ERC1155Holder {}

contract RuneStoneTest is Test, ERC1155Holder {
    RuneStone public runeStone;
    address public owner;
    address public player;
    
    event RuneStoneCreated(uint256 indexed tokenId, RuneStone.ElementType element, RuneStone.PowerLevel power);
    event RuneStoneUsed(uint256 indexed tokenId, address indexed user);
    
    function setUp() public {
        owner = address(this);
        player = makeAddr("player");
        
        // Deploy a mock receiver and get its code
        MockERC1155Receiver mockReceiver = new MockERC1155Receiver();
        vm.startPrank(player);
        // Make player an ERC1155 receiver by copying the mock receiver's code
        vm.etch(player, address(mockReceiver).code);
        vm.stopPrank();
        
        // Deploy RuneStone contract with owner
        runeStone = new RuneStone(owner);
        
        // Give player some ETH for transactions
        vm.deal(player, 100 ether);
    }
    
    function testFuzz_MintToken(address to) public {
        // Skip zero address and non-contract addresses that can't receive ERC1155
        vm.assume(to != address(0));
        if (to.code.length == 0) {
            // Deploy a mock receiver and get its code
            MockERC1155Receiver mockReceiver = new MockERC1155Receiver();
            vm.etch(to, address(mockReceiver).code);
        }
        
        // Expect the RuneStoneCreated event to be emitted
        vm.expectEmit(true, true, true, true);
        emit RuneStoneCreated(0, RuneStone.ElementType.FIRE, RuneStone.PowerLevel.COMMON);
        
        uint256 tokenId = runeStone.mint(
            to,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        assertEq(runeStone.balanceOf(to, tokenId), 1);
        
        (
            RuneStone.ElementType element,
            RuneStone.PowerLevel power,
            bool isActive
        ) = runeStone.getRuneStoneDetails(tokenId);
        
        assertEq(uint256(element), uint256(RuneStone.ElementType.FIRE));
        assertEq(uint256(power), uint256(RuneStone.PowerLevel.COMMON));
        assertTrue(isActive);
    }
    
    function test_InitialState() public view {
        assertEq(runeStone.owner(), owner);
    }
    
    function test_RevertMintToZeroAddress() public {
        vm.expectRevert("RuneStone: mint to zero address");
        runeStone.mint(
            address(0),
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
    }
    
    function test_BurnToken() public {
        // First mint a token
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.WATER,
            RuneStone.PowerLevel.RARE
        );
        
        // Expect the RuneStoneUsed event to be emitted
        vm.expectEmit(true, true, true, true);
        emit RuneStoneUsed(tokenId, player);
        
        // Burn the token as player
        vm.prank(player);
        runeStone.burn(tokenId);
        
        assertEq(runeStone.balanceOf(player, tokenId), 0);
        
        (,,bool isActive) = runeStone.getRuneStoneDetails(tokenId);
        assertFalse(isActive);
    }
    
    function test_RevertBurnInvalidToken() public {
        vm.expectRevert("RuneStone: Invalid token ID");
        runeStone.burn(999);
    }
    
    function test_RevertBurnUnownedToken() public {
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        // Try to burn token as owner (who doesn't own it)
        vm.expectRevert("RuneStone: Not token owner");
        runeStone.burn(tokenId);
    }
    
    function test_RevertBurnInactiveToken() public {
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        // Burn once
        vm.prank(player);
        runeStone.burn(tokenId);
        
        // Try to burn again
        vm.prank(player);
        vm.expectRevert("RuneStone: Token not active");
        runeStone.burn(tokenId);
    }

    function test_TokenUri() public {
        uint256 tokenId = runeStone.mint(
            player,
            RuneStone.ElementType.FIRE,
            RuneStone.PowerLevel.COMMON
        );
        
        string memory expectedUri = string(
            abi.encodePacked(
                "https://game-uri.com/api/token/",
                _toString(tokenId),
                ".json"
            )
        );
        
        assertEq(runeStone.uri(tokenId), expectedUri);
    }

    function test_RevertUriQueryNonexistentToken() public {
        vm.expectRevert("RuneStone: URI query for nonexistent token");
        runeStone.uri(999);
    }

    // Helper function to match the contract's internal _toString
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RuneStone.sol";

contract RuneStonesOfPowerTest is Test {
    RuneStonesOfPower public rsp;
    address public owner;
    address public minter;
    address public user1;
    address public user2;

    // Events for testing
    event RuneStoneCreated(uint256 indexed id, string name, uint8 power, uint8 element);
    event MinterAuthorized(address indexed minter, bool status);

    function setUp() public {
        owner = address(this);
        minter = makeAddr("minter");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy contract
        rsp = new RuneStonesOfPower();
        
        // Create initial rune stone for testing
        rsp.createRuneStone(1, "Fire Rune", 10, 0);
    }

    // Owner functionality tests
    function testCreateRuneStone() public {
        vm.expectEmit(true, false, false, true);
        emit RuneStoneCreated(2, "Water Rune", 15, 1);
        
        rsp.createRuneStone(2, "Water Rune", 15, 1);
        
        RuneStonesOfPower.RuneStone memory rune = rsp.getRuneStone(2);
        assertEq(rune.name, "Water Rune");
        assertEq(rune.power, 15);
        assertEq(rune.element, 1);
        assertTrue(rune.isActive);
    }

    function testFailCreateDuplicateRuneStone() public {
        rsp.createRuneStone(1, "Duplicate Rune", 10, 0);
    }

    function testFailCreateRuneStoneInvalidElement() public {
        rsp.createRuneStone(2, "Invalid Rune", 10, 4);
    }

    function testFailCreateRuneStoneEmptyName() public {
        rsp.createRuneStone(2, "", 10, 0);
    }

    // Minter authorization tests
    function testSetMinter() public {
        vm.expectEmit(true, false, false, true);
        emit MinterAuthorized(minter, true);
        
        rsp.setMinter(minter, true);
        assertTrue(rsp.authorizedMinters(minter));
    }

    function testFailSetMinterUnauthorized() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        rsp.setMinter(minter, true);
    }

    // Minting tests
    function testMintByAuthorizedMinter() public {
        rsp.setMinter(minter, true);
        
        vm.startPrank(minter);
        rsp.mint(user1, 1, 100, "");
        vm.stopPrank();
        
        assertEq(rsp.balanceOf(user1, 1), 100);
    }

    // Fixed: Updated error message expectation
    function testFailMintByUnauthorizedMinter() public {
        vm.startPrank(user1);
        vm.expectRevert("RuneStonesOfPower: Not authorized to mint");
        rsp.mint(user2, 1, 100, "");
        vm.stopPrank();
    }

    // Fixed: Updated error message expectation
    function testFailMintNonexistentRune() public {
        rsp.setMinter(minter, true);
        
        vm.startPrank(minter);
        vm.expectRevert("RuneStonesOfPower: Rune stone does not exist");
        rsp.mint(user1, 999, 100, "");
        vm.stopPrank();
    }

    // Batch minting tests
    function testBatchMint() public {
        // Create second rune for batch testing
        rsp.createRuneStone(2, "Water Rune", 15, 1);
        
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        
        rsp.setMinter(minter, true);
        
        vm.prank(minter);
        rsp.mintBatch(user1, ids, amounts, "");
        
        assertEq(rsp.balanceOf(user1, 1), 100);
        assertEq(rsp.balanceOf(user1, 2), 200);
    }

    // Fixed: Updated error message expectation
    function testFailBatchMintWithInvalidRune() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 999; // Nonexistent rune
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        
        rsp.setMinter(minter, true);
        
        vm.startPrank(minter);
        vm.expectRevert("RuneStonesOfPower: Rune stone does not exist");
        rsp.mintBatch(user1, ids, amounts, "");
        vm.stopPrank();
    }

    // URI tests
    function testURI() public {
        string memory expectedUri = string(
            abi.encodePacked("ipfs://YOUR_BASE_URI/", "1", ".json")
        );
        assertEq(rsp.uri(1), expectedUri);
    }

    // Fixed: Updated error message expectation
    function testFailURINonexistentToken() public {
        vm.expectRevert("RuneStonesOfPower: URI query for nonexistent token");
        rsp.uri(999);
    }

    // Burning tests
    function testBurn() public {
        // First mint some tokens
        rsp.setMinter(minter, true);
        vm.prank(minter);
        rsp.mint(user1, 1, 100, "");
        
        // Then burn them
        vm.startPrank(user1);
        rsp.burn(user1, 1, 50);
        vm.stopPrank();
        
        assertEq(rsp.balanceOf(user1, 1), 50);
    }

    function testFailBurnMoreThanBalance() public {
        rsp.setMinter(minter, true);
        vm.prank(minter);
        rsp.mint(user1, 1, 100, "");
        
        vm.startPrank(user1);
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        rsp.burn(user1, 1, 150);
        vm.stopPrank();
    }

    // Supply tracking tests
    function testSupplyTracking() public {
        rsp.setMinter(minter, true);
        vm.startPrank(minter);
        
        rsp.mint(user1, 1, 100, "");
        assertEq(rsp.totalSupply(1), 100);
        
        rsp.mint(user2, 1, 50, "");
        assertEq(rsp.totalSupply(1), 150);
        
        vm.stopPrank();
        
        vm.prank(user1);
        rsp.burn(user1, 1, 30);
        assertEq(rsp.totalSupply(1), 120);
    }
}
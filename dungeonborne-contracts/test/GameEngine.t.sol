// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GameEngine.sol";
import "../src/RuneStone.sol";
import "../src/GameItems.sol";

contract GameEngineTest is Test {
    GameEngine public gameEngine;
    RuneStonesOfPower public runeStones;
    GameItems public gameItems;
    
    address owner = address(1);
    address player1 = address(2);
    address player2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        runeStones = new RuneStonesOfPower();
        gameItems = new GameItems();
        gameEngine = new GameEngine(address(runeStones), address(gameItems));
        vm.stopPrank();
    }

    function testSpawnMonster() public {
        vm.startPrank(owner);
        
        IGameEngine.Stats memory stats = IGameEngine.Stats({
            hp: 10,
            maxHp: 10,
            ac: 12,
            str: 14,
            dex: 12,
            con: 12,
            intel: 10,
            wis: 10,
            cha: 8
        });

        gameEngine.spawnMonster("Goblin", 1, stats, 100, 100, 0);
        
        (uint256 id, string memory name, uint8 level, , , bool isActive, , ) = gameEngine.monsters(1);
        
        assertEq(id, 1);
        assertEq(name, "Goblin");
        assertEq(level, 1);
        assertTrue(isActive);
        
        vm.stopPrank();
    }

    function testSpawnMonsterFailsWithInvalidPosition() public {
        vm.startPrank(owner);
        
        IGameEngine.Stats memory stats = IGameEngine.Stats({
            hp: 10,
            maxHp: 10,
            ac: 12,
            str: 14,
            dex: 12,
            con: 12,
            intel: 10,
            wis: 10,
            cha: 8
        });

        vm.expectRevert("GameEngine: Invalid position");
        gameEngine.spawnMonster("Goblin", 1, stats, 1001, 100, 0);
        
        vm.stopPrank();
    }

    function testRegisterPlayer() public {
        vm.startPrank(player1);
        
        IGameEngine.Stats memory stats = IGameEngine.Stats({
            hp: 20,
            maxHp: 20,
            ac: 15,
            str: 16,
            dex: 14,
            con: 14,
            intel: 12,
            wis: 12,
            cha: 10
        });

        gameEngine.registerPlayer("Hero1", stats);
        
        (uint256 id, string memory name, , , bool isActive, , ) = gameEngine.players(1);
        
        assertEq(id, 1);
        assertEq(name, "Hero1");
        assertTrue(isActive);
        
        vm.stopPrank();
    }

    function testCreateQuest() public {
        vm.startPrank(owner);
        
        uint256[] memory requiredMonsters = new uint256[](1);
        requiredMonsters[0] = 1;
        
        uint256[] memory requiredItems = new uint256[](0);
        
        uint256[] memory rewardRuneIds = new uint256[](1);
        rewardRuneIds[0] = 1;
        
        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 100;

        gameEngine.createQuest(
            "Slay the Goblin",
            "Kill the goblin terrorizing the village",
            requiredMonsters,
            requiredItems,
            rewardRuneIds,
            rewardAmounts
        );
        
        (uint256 id, string memory name, , , , , , bool isActive) = gameEngine.quests(1);
        
        assertEq(id, 1);
        assertEq(name, "Slay the Goblin");
        assertTrue(isActive);
        
        vm.stopPrank();
    }

    function testInitiateCombat() public {
        // First spawn a monster
        testSpawnMonster();
        
        // Then register a player
        testRegisterPlayer();
        
        vm.startPrank(player1);
        
        gameEngine.initiateCombat(1, 1);
        
        (uint256 id, uint256 playerId, uint256 monsterId, , , bool playerTurn, bool isActive, ) = gameEngine.combats(1);
        
        assertEq(id, 1);
        assertEq(playerId, 1);
        assertEq(monsterId, 1);
        assertTrue(playerTurn);
        assertTrue(isActive);
        
        vm.stopPrank();
    }

    function testCombatTimeout() public {
        testInitiateCombat();
        
        vm.startPrank(player1);
        
        // Advance time beyond timeout
        vm.warp(block.timestamp + 31 minutes);
        
        vm.expectRevert("GameEngine: Combat timeout");
        gameEngine.performCombatAction(1);
        
        vm.stopPrank();
    }

    function testPause() public {
        vm.prank(owner);
        gameEngine.pause();
        assertTrue(gameEngine.paused());
    }

    function testUnpause() public {
        vm.startPrank(owner);
        gameEngine.pause();
        gameEngine.unpause();
        assertFalse(gameEngine.paused());
        vm.stopPrank();
    }

    function testFailPauseNonOwner() public {
        vm.prank(player1);
        vm.expectRevert("Ownable: caller is not the owner");
        gameEngine.pause();
    }
}

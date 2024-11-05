// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GameEngine.sol";
import "../src/RuneStone.sol";
import "../src/GameItems.sol";
import "../src/IGameEngine.sol";
import "../src/IGameEngine.sol";

contract GameEngineTest is Test {
    GameEngine public gameEngine;
    RuneStonesOfPower public runeStones;
    GameItems public gameItems;

    address owner = address(1);
    address player1 = address(2);
    address player2 = address(3);
    
    // Default stats for testing
    IGameEngine.Stats defaultStats = IGameEngine.Stats({
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

    function setUp() public {
        vm.startPrank(owner);
        runeStones = new RuneStonesOfPower();
        gameItems = new GameItems();
        gameEngine = new GameEngine(address(runeStones), address(gameItems));
        
        // Setup initial game state
        gameEngine.spawnMonster("Test Monster", 1, defaultStats, 100, 100, 0);
        vm.stopPrank();
    }

    function testSpawnMonster() public {
        vm.startPrank(owner);
        
        uint256 monsterId = 2; // First monster was created in setUp
        gameEngine.spawnMonster("Goblin", 1, defaultStats, 100, 100, 0);

        (
            uint256 id,
            string memory name,
            uint8 level,
            IGameEngine.Stats memory monsterStats,
            IGameEngine.Position memory pos,
            bool isActive,
            ,  // spawnTime
            // lastInteraction
        ) = gameEngine.monsters(monsterId);

        assertEq(id, monsterId, "Monster ID mismatch");
        assertEq(name, "Goblin", "Monster name mismatch");
        assertEq(level, 1, "Monster level mismatch");
        assertTrue(isActive, "Monster should be active");
        assertEq(monsterStats.hp, defaultStats.hp, "Monster HP mismatch");
        assertEq(pos.x, 100, "Monster X position mismatch");
        assertEq(pos.y, 100, "Monster Y position mismatch");

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

        IGameEngine.Stats memory playerStats = IGameEngine.Stats({
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

        gameEngine.registerPlayer("Hero1", playerStats);

        (
            uint256 id,
            address playerAddr,
            string memory name,
            IGameEngine.Stats memory statsRetrieved,
            IGameEngine.Position memory pos,
            bool isActive,
            uint256 experience,
            ,  // lastAction
            uint8 level
        ) = gameEngine.players(1);

        assertEq(id, 1, "Player ID mismatch");
        assertEq(playerAddr, player1, "Player address mismatch");
        assertEq(name, "Hero1", "Player name mismatch");
        assertTrue(isActive, "Player should be active");
        assertEq(experience, 0, "Initial experience should be 0");
        assertEq(level, 1, "Initial level should be 1");
        assertEq(statsRetrieved.hp, playerStats.hp, "Player HP mismatch");
        assertEq(pos.x, 0, "Initial X position should be 0");
        assertEq(pos.y, 0, "Initial Y position should be 0");

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

        IGameEngine.Quest memory quest = gameEngine.quests(1);

        assertEq(quest.id, 1);
        assertEq(quest.name, "Slay the Goblin");
        assertEq(quest.description, "Kill the goblin terrorizing the village");
        assertEq(quest.requiredMonsters.length, 1);
        assertEq(quest.requiredMonsters[0], 1);
        assertTrue(quest.isActive);

        vm.stopPrank();
    }

    function testInitiateCombat() public {
        // First spawn a monster
        testSpawnMonster();

        // Then register a player
        testRegisterPlayer();

        vm.startPrank(player1);

        gameEngine.initiateCombat(1, 1);

        Combat memory combat = gameEngine.combats(1);

        assertEq(combat.id, 1);
        assertEq(combat.playerId, 1);
        assertEq(combat.monsterId, 1);
        assertTrue(combat.playerTurn);
        assertTrue(combat.isActive);

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

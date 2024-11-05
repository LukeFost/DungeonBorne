// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GameEngineSpells.sol";
import "../src/RuneStone.sol";
import "../src/GameItems.sol";

contract GameEngineSpellsTest is Test {
    GameEngineSpells public gameEngineSpells;
    RuneStonesOfPower public runeStones;
    GameItems public gameItems;
    
    address owner = address(1);
    address player1 = address(2);
    address player2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        runeStones = new RuneStonesOfPower();
        gameItems = new GameItems();
        gameEngineSpells = new GameEngineSpells(address(runeStones), address(gameItems));
        vm.stopPrank();
    }

    function testCreateSpell() public {
        vm.startPrank(owner);
        
        uint256 spellId = gameEngineSpells.createSpell(
            "Fireball",
            IGameEngine.SpellSchool.EVOCATION,
            1, // level
            5, // manaCost
            10, // damage
            IGameEngine.DamageType.FIRE,
            IGameEngine.StatusEffect.BURNING,
            50, // effectChance
            6, // cooldown
            true, // isAoE
            3 // aoeRadius
        );
        
        IGameEngine.Spell memory spell = gameEngineSpells.getSpell(spellId);
        
        assertEq(spell.name, "Fireball");
        assertEq(uint(spell.school), uint(IGameEngine.SpellSchool.EVOCATION));
        assertEq(spell.level, 1);
        assertEq(spell.manaCost, 5);
        assertEq(spell.damage, 10);
        assertEq(uint(spell.damageType), uint(IGameEngine.DamageType.FIRE));
        assertEq(uint(spell.effect), uint(IGameEngine.StatusEffect.BURNING));
        assertEq(spell.effectChance, 50);
        assertEq(spell.cooldown, 6);
        assertTrue(spell.isAoE);
        assertEq(spell.aoeRadius, 3);
        
        vm.stopPrank();
    }

    function testCastSpell() public {
        // First create a spell and register a player
        testCreateSpell();
        
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

        gameEngineSpells.registerPlayer("Mage", stats);
        
        // Learn the spell
        gameEngineSpells.learnSpell(1);
        
        // Cast the spell
        gameEngineSpells.castSpell(1, 0, 100, 100);
        
        // Verify cooldown
        uint256[] memory spellIds;
        uint256[] memory timestamps;
        (spellIds, timestamps) = gameEngineSpells.getCooldowns(1);
        
        assertEq(spellIds.length, 1);
        assertEq(spellIds[0], 1);
        assertTrue(timestamps[0] > 0);
        
        vm.stopPrank();
    }

    function testFailCastUnlearnedSpell() public {
        vm.startPrank(player1);
        vm.expectRevert("Spell not learned");
        gameEngineSpells.castSpell(1, 0, 100, 100);
        vm.stopPrank();
    }

    function testFailCastSpellOnCooldown() public {
        testCastSpell();
        
        vm.startPrank(player1);
        vm.expectRevert("Spell on cooldown");
        gameEngineSpells.castSpell(1, 0, 100, 100);
        vm.stopPrank();
    }

    function testGetGameState() public {
        testCastSpell();
        
        IGameEngine.GameState memory state = gameEngineSpells.getGameState(1);
        
        assertEq(state.playerId, 1);
        assertEq(state.playerStats.hp, 20);
        assertEq(state.availableSpells.length, 1);
        assertEq(state.availableSpells[0], 1);
    }

    function testStatusEffects() public {
        testCastSpell();
        
        IGameEngine.StatusEffect[] memory effects = gameEngineSpells.getActiveEffects(1);
        assertEq(effects.length, 0);
        
        // TODO: Add more tests when status effect application is implemented
    }

    function testSpellLearning() public {
        testCreateSpell();
        
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

        gameEngineSpells.registerPlayer("Mage", stats);
        
        gameEngineSpells.learnSpell(1);
        
        uint256[] memory spells = gameEngineSpells.getPlayerSpells(1);
        assertEq(spells.length, 1);
        assertEq(spells[0], 1);
        
        vm.stopPrank();
    }

    function testFailLearnSpellTwice() public {
        testSpellLearning();
        
        vm.startPrank(player1);
        vm.expectRevert("Spell already learned");
        gameEngineSpells.learnSpell(1);
        vm.stopPrank();
    }
}

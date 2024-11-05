// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GameEngine.sol";
import "./IGameEngine.sol";

contract GameEngineSpells is GameEngine, IGameEngine {
    // Spell and Ability storage
    mapping(uint256 => Spell) public spells;
    mapping(uint256 => Ability) public abilities;
    
    // Player spell and ability management
    mapping(uint256 => mapping(uint256 => bool)) public playerSpells; // playerId => spellId => owned
    mapping(uint256 => mapping(uint256 => bool)) public playerAbilities; // playerId => abilityId => owned
    mapping(uint256 => mapping(uint256 => uint256)) public spellCooldowns; // playerId => spellId => timestamp
    mapping(uint256 => mapping(uint256 => uint256)) public abilityCooldowns; // playerId => abilityId => timestamp
    
    // Status effects
    mapping(uint256 => mapping(StatusEffect => uint256)) public statusEffects; // targetId => effect => expiry
    
    // Spell creation and management
    function createSpell(
        string calldata name,
        SpellSchool school,
        uint8 level,
        uint8 manaCost,
        uint8 damage,
        DamageType damageType,
        StatusEffect effect,
        uint8 effectChance,
        uint8 cooldown,
        bool isAoE,
        uint8 aoeRadius
    ) external onlyOwner returns (uint256 spellId) {
        spellId = uint256(keccak256(abi.encodePacked(name, block.timestamp)));
        
        spells[spellId] = Spell({
            id: spellId,
            name: name,
            school: school,
            level: level,
            manaCost: manaCost,
            damage: damage,
            damageType: damageType,
            effect: effect,
            effectChance: effectChance,
            cooldown: cooldown,
            isAoE: isAoE,
            aoeRadius: aoeRadius
        });
    }

    // Spell casting system
    function castSpell(
        uint256 spellId,
        uint256 targetId,
        uint16 targetX,
        uint16 targetY
    ) external whenNotPaused {
        require(playerSpells[msg.sender][spellId], "Spell not learned");
        require(
            block.timestamp >= spellCooldowns[msg.sender][spellId],
            "Spell on cooldown"
        );
        
        Spell memory spell = spells[spellId];
        Player storage player = players[msg.sender];
        
        // Handle AoE spells
        if (spell.isAoE) {
            _handleAoESpell(spell, targetX, targetY);
        } else {
            _handleSingleTargetSpell(spell, targetId);
        }
        
        // Apply cooldown
        spellCooldowns[msg.sender][spellId] = block.timestamp + spell.cooldown;
        
        emit SpellCast(msg.sender, spellId, targetId, true, spell.damage);
    }

    // AoE spell handling
    function _handleAoESpell(
        Spell memory spell,
        uint16 targetX,
        uint16 targetY
    ) internal {
        // Find all valid targets in radius
        for (uint256 i = 1; i < nextMonsterId; i++) {
            Monster storage monster = monsters[i];
            if (!monster.isActive) continue;
            
            if (_isInRange(
                targetX,
                targetY,
                monster.pos.x,
                monster.pos.y,
                spell.aoeRadius
            )) {
                _applySpellEffects(spell, i);
            }
        }
    }

    // Single target spell handling
    function _handleSingleTargetSpell(
        Spell memory spell,
        uint256 targetId
    ) internal {
        require(monsters[targetId].isActive, "Invalid target");
        _applySpellEffects(spell, targetId);
    }

    // Apply spell effects
    function _applySpellEffects(
        Spell memory spell,
        uint256 targetId
    ) internal {
        Monster storage monster = monsters[targetId];
        
        // Apply damage
        if (spell.damage > 0) {
            uint8 newHp = monster.stats.hp;
            if (spell.damage >= newHp) {
                newHp = 0;
            } else {
                newHp -= spell.damage;
            }
            monster.stats.hp = newHp;
        }
        
        // Apply status effect
        if (spell.effect != StatusEffect.NONE) {
            if (_randomChance(spell.effectChance)) {
                _applyStatusEffect(targetId, spell.effect);
            }
        }
    }

    // Status effect system
    function _applyStatusEffect(
        uint256 targetId,
        StatusEffect effect
    ) internal {
        uint256 duration = block.timestamp + 5 minutes; // Standard 5-minute effect
        statusEffects[targetId][effect] = duration;
        
        emit StatusEffectApplied(targetId, effect, duration);
    }

    // Helper functions
    function _isInRange(
        uint16 x1,
        uint16 y1,
        uint16 x2,
        uint16 y2,
        uint8 radius
    ) internal pure returns (bool) {
        uint16 dx = x1 > x2 ? x1 - x2 : x2 - x1;
        uint16 dy = y1 > y2 ? y1 - y2 : y2 - y1;
        return (dx * dx + dy * dy) <= radius * radius;
    }

    function _randomChance(uint8 percentage) internal view returns (bool) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100) < percentage;
    }

    // View functions for frontend
    function getGameState(uint256 playerId) external view override returns (GameState memory) {
        Player memory player = players[playerId];
        
        // Get active quests
        uint256[] memory activeQuests = new uint256[](nextQuestId);
        uint256 activeQuestCount = 0;
        for (uint256 i = 1; i < nextQuestId; i++) {
            if (quests[i].isActive) {
                activeQuests[activeQuestCount++] = i;
            }
        }
        
        // Get available spells
        uint256[] memory availableSpells = new uint256[](100); // Adjust size as needed
        uint256 spellCount = 0;
        for (uint256 i = 1; i < 100; i++) {
            if (playerSpells[playerId][i]) {
                availableSpells[spellCount++] = i;
            }
        }
        
        // Get active effects
        StatusEffect[] memory activeEffects = new StatusEffect[](10);
        uint256 effectCount = 0;
        for (uint8 i = 0; i < 10; i++) {
            StatusEffect effect = StatusEffect(i);
            if (statusEffects[playerId][effect] > block.timestamp) {
                activeEffects[effectCount++] = effect;
            }
        }
        
        return GameState({
            playerId: playerId,
            playerStats: player.stats,
            playerPos: player.pos,
            activeQuests: activeQuests,
            currentCombatId: _getCurrentCombatId(playerId),
            availableSpells: availableSpells,
            availableAbilities: new uint256[](0), // Implement as needed
            activeEffects: activeEffects,
            inventory: new uint256[](0) // Implement as needed
        });
    }

    function _getCurrentCombatId(uint256 playerId) internal view returns (uint256) {
        for (uint256 i = 1; i < nextCombatId; i++) {
            if (combats[i].isActive && combats[i].playerId == playerId) {
                return i;
            }
        }
        return 0;
    }
}

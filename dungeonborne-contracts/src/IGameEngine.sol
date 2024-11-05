// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Common structs used across interfaces
struct Position {
    uint16 x;
    uint16 y;
    uint16 facing;
}

interface IGameEngine {
    // Enums
    enum SpellSchool { NONE, EVOCATION, ABJURATION, CONJURATION, DIVINATION, ENCHANTMENT, ILLUSION, NECROMANCY, TRANSMUTATION }
    enum AbilityType { PASSIVE, ACTIVE, ULTIMATE }
    enum DamageType { PHYSICAL, FIRE, COLD, LIGHTNING, POISON, NECROTIC, RADIANT, FORCE }
    enum StatusEffect { NONE, STUNNED, POISONED, BLESSED, CURSED, FROZEN, BURNING }

    // Structs
    struct Stats {
        uint8 hp;
        uint8 maxHp;
        uint8 ac;
        uint8 str;
        uint8 dex;
        uint8 con;
        uint8 intel;
        uint8 wis;
        uint8 cha;
    }


    struct Spell {
        uint256 id;
        string name;
        SpellSchool school;
        uint8 level;
        uint8 manaCost;
        uint8 damage;
        DamageType damageType;
        StatusEffect effect;
        uint8 effectChance; // Percentage chance (0-100)
        uint8 cooldown;
        bool isAoE;
        uint8 aoeRadius;
    }

    struct Ability {
        uint256 id;
        string name;
        AbilityType abilityType;
        uint8 level;
        uint8 energyCost;
        uint8 damage;
        DamageType damageType;
        StatusEffect effect;
        uint8 effectChance;
        uint8 cooldown;
        bool isActive;
    }

    struct GameState {
        uint256 playerId;
        Stats playerStats;
        Position playerPos;
        uint256[] activeQuests;
        uint256 currentCombatId;
        uint256[] availableSpells;
        uint256[] availableAbilities;
        StatusEffect[] activeEffects;
        uint256[] inventory;
    }

    // View Functions
    function getGameState(uint256 playerId) external view returns (GameState memory);
    function getSpell(uint256 spellId) external view returns (Spell memory);
    function getAbility(uint256 abilityId) external view returns (Ability memory);
    function getActiveEffects(uint256 playerId) external view returns (StatusEffect[] memory);
    function getCooldowns(uint256 playerId) external view returns (uint256[] memory spellIds, uint256[] memory timestamps);
    function getQuestProgress(uint256 questId, uint256 playerId) external view returns (bool[] memory completed);
    function getPlayerSpells(uint256 playerId) external view returns (uint256[] memory spellIds);
    function getPlayerAbilities(uint256 playerId) external view returns (uint256[] memory abilityIds);

    // Event Definitions
    event SpellCast(uint256 indexed playerId, uint256 indexed spellId, uint256 indexed targetId, bool hit, uint256 damage);
    event AbilityUsed(uint256 indexed playerId, uint256 indexed abilityId, bool success);
    event StatusEffectApplied(uint256 indexed targetId, StatusEffect effect, uint256 duration);
    event StatusEffectRemoved(uint256 indexed targetId, StatusEffect effect);
    event SpellLearned(uint256 indexed playerId, uint256 indexed spellId);
    event AbilityUnlocked(uint256 indexed playerId, uint256 indexed abilityId);
    event PlayerLevelUp(uint256 indexed playerId, uint8 newLevel);
    event ItemUsed(uint256 indexed playerId, uint256 indexed itemId);
}

interface IGameEvents {
    event CombatRoundStart(uint256 indexed combatId, uint256 roundNumber);
    event CombatRoundEnd(uint256 indexed combatId, uint256 roundNumber);
    event MonsterSpawn(uint256 indexed monsterId, string name, Position position);
    event MonsterDespawn(uint256 indexed monsterId);
    event QuestAvailable(uint256 indexed questId, string name);
    event QuestCompleted(uint256 indexed questId, uint256 indexed playerId);
    event TreasureFound(uint256 indexed playerId, uint256 indexed itemId, uint256 amount);
    event PlayerMoved(uint256 indexed playerId, Position newPosition);
    event EnvironmentalEffect(uint16 x, uint16 y, string effect, uint256 duration);
}

interface IGameActions {
    function castSpell(uint256 spellId, uint256 targetId, uint16 targetX, uint16 targetY) external;
    function useAbility(uint256 abilityId, uint256 targetId) external;
    function movePlayer(uint16 x, uint16 y, uint16 facing) external;
    function useItem(uint256 itemId, uint256 targetId) external;
    function startQuest(uint256 questId) external;
    function claimQuestReward(uint256 questId) external;
    function learnSpell(uint256 spellId) external;
    function upgradeAbility(uint256 abilityId) external;
    function restPlayer() external;
    function craftItem(uint256 recipeId, uint256[] memory ingredients) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGameEngine {
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
        uint8 effectChance;
        uint8 cooldown;
        bool isAoE;
        uint8 aoeRadius;
    }

    struct Ability {
        uint256 id;
        string name;
        string description;
        uint8 levelRequirement;
        uint8 cooldown;
    }

    enum SpellSchool {
        EVOCATION,
        CONJURATION,
        ILLUSION,
        NECROMANCY,
        TRANSMUTATION,
        DIVINATION,
        ABJURATION,
        ENCHANTMENT
    }

    enum DamageType {
        FIRE,
        WATER,
        EARTH,
        AIR,
        LIGHTNING,
        ICE,
        ARCANE,
        HOLY,
        SHADOW,
        PHYSICAL
    }

    enum StatusEffect {
        NONE,
        POISONED,
        STUNNED,
        BURNING,
        FROZEN,
        PARALYZED,
        CHARMED,
        SLOWED,
        WEAKENED,
        BLINDED
    }

    struct Position {
        uint16 x;
        uint16 y;
        uint16 facing;
    }

    struct Quest {
        uint256 id;
        string name;
        string description;
        uint256[] requiredMonsters;
        uint256[] requiredItems;
        uint256[] rewardRuneIds;
        uint256[] rewardAmounts;
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

    // Events
    event SpellCast(uint256 indexed playerId, uint256 indexed spellId, uint256 targetId, bool success, uint256 damage);
    event StatusEffectApplied(uint256 indexed targetId, StatusEffect effect, uint256 expiry);
    event SpellLearned(uint256 indexed playerId, uint256 indexed spellId);

    function getSpell(uint256 spellId) external view returns (Spell memory);

    function getAbility(uint256 abilityId) external view returns (Ability memory);

    function getActiveEffects(uint256 playerId) external view returns (StatusEffect[] memory);

    function getCooldowns(uint256 playerId) external view returns (uint256[] memory spellIds, uint256[] memory timestamps);

    function getQuestProgress(uint256 questId, uint256 playerId) external view returns (bool[] memory completed);

    function getPlayerSpells(uint256 playerId) external view returns (uint256[] memory spellIds);

    function getPlayerAbilities(uint256 playerId) external view returns (uint256[] memory abilityIds);

    function getGameState(uint256 playerId) external view returns (GameState memory);
}

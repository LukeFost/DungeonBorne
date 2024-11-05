// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts//contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts//contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts//contracts/utils/Pausable.sol";
interface LinkWellNodesClient {
    function requestRandomness(
        bytes32 _jobId,
        uint256 _fee,
        uint256 _seed
    ) external returns (bytes32 requestId);
}
import "./RuneStone.sol";
import "./GameItems.sol";
import "./IGameEngine.sol";

contract GameEngine is Ownable, ReentrancyGuard, Pausable, IGameEngine {
    // Contract references
    RuneStonesOfPower public immutable runeStones;
    GameItems public immutable gameItems;

    // VRF configuration
    LinkWellNodesClient private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // Game structures
    struct Monster {
        uint256 id;
        string name;
        uint8 level;
        Stats stats;
        Position pos;
        bool isActive;
        uint256 spawnTime;
        uint256 lastInteraction;
    }

    struct Player {
        uint256 id;
        string name;
        Stats stats;
        Position pos;
        bool isActive;
        uint256 experience;
        uint256 lastAction;
        uint8 level;
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

    struct Combat {
        uint256 id;
        uint256 playerId;
        uint256 monsterId;
        uint8 playerHp;
        uint8 monsterHp;
        bool playerTurn;
        bool isActive;
        uint256 lastAction;
        uint256[] pendingRolls;
    }

    // Game state
    uint256 public constant GRID_SIZE = 1000;
    uint256 public constant COMBAT_TIMEOUT = 30 minutes;
    uint256 public constant MONSTER_DESPAWN_TIME = 1 days;
    
    mapping(uint256 => Monster) public monsters;
    mapping(uint256 => Player) public players;
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => Combat) public combats;
    mapping(uint256 => mapping(uint256 => bool)) public questProgress; // questId => monsterId => defeated
    
    // Counters
    uint256 public nextMonsterId = 1;
    uint256 public nextPlayerId = 1;
    uint256 public nextQuestId = 1;
    uint256 public nextCombatId = 1;

    // VRF request mappings
    mapping(bytes32 => address) public rollRequests; // requestId => player
    mapping(bytes32 => uint256) public combatRolls; // requestId => combatId

    // Events
    event MonsterSpawned(uint256 indexed id, string name, uint8 level, uint16 x, uint16 y);
    event PlayerRegistered(uint256 indexed id, string name);
    event QuestCreated(uint256 indexed id, string name);
    event QuestCompleted(uint256 indexed questId, uint256 indexed playerId);
    event CombatStarted(uint256 indexed combatId, uint256 indexed playerId, uint256 indexed monsterId);
    event CombatAction(uint256 indexed combatId, bool isPlayerAction, uint256 roll, uint256 damage);
    event CombatEnded(uint256 indexed combatId, bool playerWon);
    event DiceRollRequested(bytes32 indexed requestId, uint256 indexed combatId);
    event DiceRollCompleted(bytes32 indexed requestId, uint256 result);

    constructor(
        address _runeStones,
        address _gameItems
    ) Ownable(msg.sender) {
        oracle = LinkWellNodesClient(0x14bc7F6Da6cA3E072793c185e01a76E62341CC61);
        runeStones = RuneStonesOfPower(_runeStones);
        gameItems = GameItems(_gameItems);
        jobId = "92b7c5a0307545d9ad032f00523605a0";
        fee = 0; // 0 LINK
    }

    // Monster Management Functions
    function spawnMonster(
        string calldata name,
        uint8 level,
        Stats calldata stats,
        uint16 x,
        uint16 y,
        uint16 facing
    ) external onlyOwner {
        require(x < GRID_SIZE && y < GRID_SIZE, "GameEngine: Invalid position");
        require(stats.hp > 0, "GameEngine: Invalid HP");

        uint256 monsterId = nextMonsterId++;
        
        monsters[monsterId] = Monster({
            id: monsterId,
            name: name,
            level: level,
            stats: stats,
            pos: Position({x: x, y: y, facing: facing}),
            isActive: true,
            spawnTime: block.timestamp,
            lastInteraction: block.timestamp
        });

        emit MonsterSpawned(monsterId, name, level, x, y);
    }

    // Player Management Functions
    function registerPlayer(
        string calldata name,
        Stats calldata stats
    ) external {
        require(!players[nextPlayerId].isActive, "GameEngine: Player ID taken");
        require(bytes(name).length > 0, "GameEngine: Name required");
        require(stats.hp > 0, "GameEngine: Invalid HP");

        uint256 playerId = nextPlayerId++;
        
        players[playerId] = Player({
            id: playerId,
            name: name,
            stats: stats,
            pos: Position({x: 0, y: 0, facing: 0}),
            isActive: true,
            experience: 0,
            lastAction: block.timestamp
        });

        emit PlayerRegistered(playerId, name);
    }

    // Quest Management Functions
    function createQuest(
        string calldata name,
        string calldata description,
        uint256[] calldata requiredMonsters,
        uint256[] calldata requiredItems,
        uint256[] calldata rewardRuneIds,
        uint256[] calldata rewardAmounts
    ) external onlyOwner {
        require(bytes(name).length > 0, "GameEngine: Name required");
        require(rewardRuneIds.length == rewardAmounts.length, "GameEngine: Reward mismatch");

        uint256 questId = nextQuestId++;
        
        quests[questId] = Quest({
            id: questId,
            name: name,
            description: description,
            requiredMonsters: requiredMonsters,
            requiredItems: requiredItems,
            rewardRuneIds: rewardRuneIds,
            rewardAmounts: rewardAmounts,
            isActive: true
        });

        emit QuestCreated(questId, name);
    }

    // Combat Functions
    function initiateCombat(uint256 playerId, uint256 monsterId) external {
        require(players[playerId].isActive, "GameEngine: Invalid player");
        require(monsters[monsterId].isActive, "GameEngine: Invalid monster");
        require(!isPlayerInCombat(playerId), "GameEngine: Already in combat");

        uint256 combatId = nextCombatId++;
        
        combats[combatId] = Combat({
            id: combatId,
            playerId: playerId,
            monsterId: monsterId,
            playerHp: players[playerId].stats.hp,
            monsterHp: monsters[monsterId].stats.hp,
            playerTurn: true,
            isActive: true,
            lastAction: block.timestamp,
            pendingRolls: new uint256[](0)
        });

        emit CombatStarted(combatId, playerId, monsterId);
        requestDiceRoll(combatId); // Initial initiative roll
    }

    function performCombatAction(uint256 combatId) external {
        Combat storage combat = combats[combatId];
        require(combat.isActive, "GameEngine: Combat not active");
        require(block.timestamp - combat.lastAction <= COMBAT_TIMEOUT, "GameEngine: Combat timeout");

        if (combat.playerTurn) {
            require(msg.sender == players[combat.playerId].id, "GameEngine: Not player's turn");
        }

        requestDiceRoll(combatId);
    }

    // VRF Functions
    function requestDiceRoll(uint256 combatId) internal returns (bytes32 requestId) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
        
        requestId = oracle.requestRandomness(jobId, fee, seed);
        
        rollRequests[requestId] = msg.sender;
        combatRolls[requestId] = combatId;
        emit DiceRollRequested(requestId, combatId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) external {
        require(msg.sender == address(oracle), "Only LinkWellNodes can fulfill");
        uint256 combatId = combatRolls[_requestId];
        Combat storage combat = combats[combatId];
        require(combat.isActive, "GameEngine: Combat not active");

        uint256 roll = (_randomness % 20) + 1; // Ensure the roll is between 1 and 20
        processCombatRoll(combatId, roll);
        
        emit DiceRollCompleted(_requestId, roll);
    }

    function processCombatRoll(uint256 combatId, uint256 roll) internal {
        Combat storage combat = combats[combatId];
        Player storage player = players[combat.playerId];
        Monster storage monster = monsters[combat.monsterId];

        uint256 damage = 0;
        if (combat.playerTurn) {
            if (roll >= monster.stats.ac) {
                damage = calculateDamage(player.stats.str);
                combat.monsterHp -= uint8(Math.min(damage, combat.monsterHp));
            }
        } else {
            if (roll >= player.stats.ac) {
                damage = calculateDamage(monster.stats.str);
                combat.playerHp -= uint8(Math.min(damage, combat.playerHp));
            }
        }

        emit CombatAction(combatId, combat.playerTurn, roll, damage);

        // Check for combat end
        if (combat.playerHp == 0 || combat.monsterHp == 0) {
            endCombat(combatId, combat.monsterHp == 0);
        } else {
            combat.playerTurn = !combat.playerTurn;
            combat.lastAction = block.timestamp;
        }
    }

    // Helper Functions
    function calculateDamage(uint8 strength) internal pure returns (uint256) {
        return (strength / 2) + 1; // Basic damage formula
    }

    function isPlayerInCombat(uint256 playerId) public view returns (bool) {
        for (uint256 i = 1; i < nextCombatId; i++) {
            if (combats[i].isActive && combats[i].playerId == playerId) {
                return true;
            }
        }
        return false;
    }

    function endCombat(uint256 combatId, bool playerWon) internal {
        Combat storage combat = combats[combatId];
        combat.isActive = false;

        if (playerWon) {
            // Update quest progress if applicable
            uint256 playerId = combat.playerId;
            uint256 monsterId = combat.monsterId;
            for (uint256 i = 1; i < nextQuestId; i++) {
                Quest storage quest = quests[i];
                if (!quest.isActive) continue;
                
                for (uint256 j = 0; j < quest.requiredMonsters.length; j++) {
                    if (quest.requiredMonsters[j] == monsterId) {
                        questProgress[i][monsterId] = true;
                    }
                }
            }

            // Award experience
            Player storage player = players[combat.playerId];
            Monster storage monster = monsters[combat.monsterId];
            player.experience += calculateExperience(player.level, monster.level);
        }

        emit CombatEnded(combatId, playerWon);
    }

    function calculateExperience(uint8 playerLevel, uint8 monsterLevel) internal pure returns (uint256) {
        // Basic experience formula
        if (playerLevel >= monsterLevel) {
            return 100 * uint256(monsterLevel) / uint256(playerLevel);
        } else {
            return 100 * uint256(monsterLevel);
        }
    }

    // Admin Functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

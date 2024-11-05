// IGameEngine.sol
interface IGameEngine {
    // Structs
    struct Monster {
        uint8 hp;
        uint8 ac;
        uint8 str;
        uint8 dex;
        uint8 con;
        uint8 smt;
        uint8 wis;
        uint8 cha;
        uint16 xPos;
        uint16 yPos;
        uint16 facing; // 0-359 degrees
        bool isActive;
    }
    
    // Events
    event MonsterSpawned(uint256 indexed monsterId, uint16 x, uint16 y, uint16 facing);
    event MonsterDefeated(uint256 indexed monsterId);
    event CombatResult(uint256 indexed monsterId, address indexed player, uint8 damage, bool hit);
    
    // Core functions
    function spawnMonster(
        uint256 monsterId,
        uint8 hp,
        uint8 ac,
        uint8[6] calldata stats,
        uint16 x,
        uint16 y,
        uint16 facing
    ) external;
    
    function attack(uint256 monsterId, uint256 runeStoneId) external;
    function getMonster(uint256 monsterId) external view returns (Monster memory);
}
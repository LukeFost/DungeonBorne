// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// IRuneStone.sol
interface IRuneStone {
    // Enums
    enum ElementType { FIRE, WATER, EARTH, AIR, VOID }
    enum PowerLevel { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
    
    // Events
    event RuneStoneCreated(uint256 indexed tokenId, ElementType element, PowerLevel power);
    event RuneStoneUsed(uint256 indexed tokenId, address indexed user);
    
    // Core functions
    function mint(address to, ElementType element, PowerLevel power) external returns (uint256);
    function burn(uint256 tokenId) external;
    function getRuneStoneDetails(uint256 tokenId) external view returns (
        ElementType element,
        PowerLevel power,
        bool isActive
    );
}

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

// RuneStone.sol
import "../lib/openzeppelin-contracts//contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts//contracts/access/Ownable.sol";
import "./IRuneStone.sol";

contract RuneStone is ERC1155, Ownable, IRuneStone {
    // State variables
    mapping(uint256 => ElementType) private _elements;
    mapping(uint256 => PowerLevel) private _powerLevels;
    mapping(uint256 => bool) private _active;
    uint256 private _tokenIds;
    
    constructor() ERC1155("https://game-uri.com/api/token/{id}.json") {}
    
    function mint(
        address to,
        ElementType element,
        PowerLevel power
    ) external override onlyOwner returns (uint256) {
        uint256 newTokenId = _tokenIds++;
        _elements[newTokenId] = element;
        _powerLevels[newTokenId] = power;
        _active[newTokenId] = true;
        
        _mint(to, newTokenId, 1, "");
        
        emit RuneStoneCreated(newTokenId, element, power);
        return newTokenId;
    }
    
    function burn(uint256 tokenId) external override {
        require(_active[tokenId], "RuneStone: Token not active");
        require(balanceOf(msg.sender, tokenId) > 0, "RuneStone: Not token owner");
        
        _burn(msg.sender, tokenId, 1);
        _active[tokenId] = false;
    }
    
    function getRuneStoneDetails(uint256 tokenId) external view override returns (
        ElementType element,
        PowerLevel power,
        bool isActive
    ) {
        require(_exists(tokenId), "RuneStone: Token does not exist");
        return (
            _elements[tokenId],
            _powerLevels[tokenId],
            _active[tokenId]
        );
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _tokenIds;
    }
}

// GameEngine.sol
import "./IGameEngine.sol";
import "./IRuneStone.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract GameEngine is IGameEngine, VRFV2WrapperConsumerBase {
    // State variables
    IRuneStone public runeStone;
    mapping(uint256 => Monster) private monsters;
    
    // Chainlink VRF variables
    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    
    constructor(
        address _runeStone,
        address _linkToken,
        address _vrfWrapper
    ) VRFV2WrapperConsumerBase(_linkToken, _vrfWrapper) {
        runeStone = IRuneStone(_runeStone);
    }
    
    function spawnMonster(
        uint256 monsterId,
        uint8 hp,
        uint8 ac,
        uint8[6] calldata stats,
        uint16 x,
        uint16 y,
        uint16 facing
    ) external override {
        require(facing < 360, "GameEngine: Invalid facing direction");
        
        monsters[monsterId] = Monster({
            hp: hp,
            ac: ac,
            str: stats[0],
            dex: stats[1],
            con: stats[2],
            smt: stats[3],
            wis: stats[4],
            cha: stats[5],
            xPos: x,
            yPos: y,
            facing: facing,
            isActive: true
        });
        
        emit MonsterSpawned(monsterId, x, y, facing);
    }
    
    function attack(uint256 monsterId, uint256 runeStoneId) external override {
        require(monsters[monsterId].isActive, "GameEngine: Monster not active");
        
        // Request random number for attack roll
        requestRandomness(
            CALLBACK_GAS_LIMIT,
            REQUEST_CONFIRMATIONS,
            NUM_WORDS
        );
        
        // Note: In a full implementation, we would handle the random number callback
        // and complete the attack logic there. For MVP, we'll simulate with a basic hit.
        
        monsters[monsterId].hp = monsters[monsterId].hp > 10 ? 
            monsters[monsterId].hp - 10 : 0;
            
        if (monsters[monsterId].hp == 0) {
            monsters[monsterId].isActive = false;
            emit MonsterDefeated(monsterId);
        }
        
        emit CombatResult(monsterId, msg.sender, 10, true);
    }
    
    function getMonster(uint256 monsterId) external view override returns (Monster memory) {
        require(monsters[monsterId].isActive, "GameEngine: Monster not active");
        return monsters[monsterId];
    }
    
    // VRF callback - would be implemented with proper combat resolution
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Implementation will handle combat resolution with random numbers
    }
}
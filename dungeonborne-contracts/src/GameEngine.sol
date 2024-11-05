// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IGameEngine.sol";
import "./IRuneStone.sol";
import "../lib/chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract GameEngine is IGameEngine, VRFV2WrapperConsumerBase {
    // State variables
    IRuneStone public runeStone;
    mapping(uint256 => Monster) private monsters;
    mapping(uint256 => uint256) private requestIdToMonsterId;
    
    // Chainlink VRF variables
    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    
    // Base damage for testing
    uint8 private constant BASE_DAMAGE = 10;
    
    constructor(
        address _runeStone,
        address _linkToken,
        address _vrfWrapper
    ) VRFV2WrapperConsumerBase(_linkToken, _vrfWrapper) {
        require(_runeStone != address(0), "GameEngine: RuneStone address cannot be 0");
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
        require(!monsters[monsterId].isActive, "GameEngine: Monster ID already in use");
        
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
        
        // For MVP, we'll do direct damage without waiting for VRF
        // In production, we would wait for the VRF callback before applying damage
        applyDamage(monsterId, BASE_DAMAGE);
        
        emit CombatResult(monsterId, msg.sender, BASE_DAMAGE, true);
    }
    
    function getMonster(uint256 monsterId) external view override returns (Monster memory) {
        require(monsters[monsterId].isActive, "GameEngine: Monster not active");
        return monsters[monsterId];
    }
    
    // Internal functions
    function applyDamage(uint256 monsterId, uint8 damage) internal {
        Monster storage monster = monsters[monsterId];
        
        if (damage >= monster.hp) {
            monster.hp = 0;
            monster.isActive = false;
            emit MonsterDefeated(monsterId);
        } else {
            monster.hp -= damage;
        }
    }
    
    // VRF callback - would be implemented with proper combat resolution
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Implementation will handle combat resolution with random numbers
    }
}
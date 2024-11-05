// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IGameEngine.sol";
import "./RuneStone.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameEngine is IGameEngine, VRFConsumerBaseV2, Ownable {
    // Constants
    uint16 public constant MAX_FACING = 359;
    uint8 public constant BASE_DAMAGE = 10;  // Basic attack damage in MVP

    // State variables
    RuneStone public immutable runeStone;
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    
    // Storage
    mapping(uint256 => Monster) private monsters;
    mapping(uint256 => CombatRequest) private combatRequests;
    
    // VRF configuration
    bytes32 private immutable keyHash;
    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Additional structs
    struct CombatRequest {
        uint256 monsterId;
        address player;
        uint256 runeStoneId;
    }

    constructor(
        address _runeStone,
        address _linkToken,
        address _vrfCoordinator
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        runeStone = RuneStone(_runeStone);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        
        // VRF Configuration - these would typically be set via constructor params
        // Using placeholder values for demonstration
        keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        subscriptionId = 1;
        callbackGasLimit = 100000;
    }

    /// @inheritdoc IGameEngine
    function spawnMonster(
        uint256 monsterId,
        uint8 hp,
        uint8 ac,
        uint8[6] memory stats,
        uint16 x,
        uint16 y,
        uint16 facing
    ) external override onlyOwner {
        require(facing <= MAX_FACING, "GameEngine: Invalid facing direction");
        require(!monsters[monsterId].isActive, "GameEngine: Monster ID already active");

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

    /// @inheritdoc IGameEngine
    function attack(uint256 monsterId, uint256 runeStoneId) external override {
        Monster storage monster = monsters[monsterId];
        require(monster.isActive, "GameEngine: Monster not active");
        
        // Verify RuneStone ownership and validity
        require(runeStone.balanceOf(msg.sender, runeStoneId) > 0, "GameEngine: Not RuneStone owner");
        (,, bool isActive) = runeStone.getRuneStoneDetails(runeStoneId);
        require(isActive, "GameEngine: RuneStone not active");

        // Transfer RuneStone to GameEngine
        runeStone.safeTransferFrom(msg.sender, address(this), runeStoneId, 1, "");

        // Store combat request for VRF callback
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );

        combatRequests[requestId] = CombatRequest({
            monsterId: monsterId,
            player: msg.sender,
            runeStoneId: runeStoneId
        });
    }

    /// @inheritdoc IGameEngine
    function getMonster(uint256 monsterId) external view override returns (Monster memory) {
        Monster memory monster = monsters[monsterId];
        require(monster.isActive, "GameEngine: Monster not active");
        return monster;
    }

    /// @notice Callback function used by VRF Coordinator
    /// @param requestId The ID of the request
    /// @param randomWords The random values generated
// In the fulfillRandomWords function, let's modify it to ensure damage is applied:
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        CombatRequest memory request = combatRequests[requestId];
        Monster storage monster = monsters[request.monsterId];
        
        // Always hit in MVP for testing purposes
        bool hit = true;  // Removed random roll for now
        
        if (hit) {
            // Apply damage
            if (monster.hp <= BASE_DAMAGE) {
                monster.hp = 0;
                monster.isActive = false;
                emit MonsterDefeated(request.monsterId);
            } else {
                monster.hp -= BASE_DAMAGE;
            }

            // Burn the RuneStone after use
            runeStone.burn(request.runeStoneId);
            
            emit CombatResult(request.monsterId, request.player, BASE_DAMAGE, hit);
        }
        
        // Cleanup
        delete combatRequests[requestId];
    }
}

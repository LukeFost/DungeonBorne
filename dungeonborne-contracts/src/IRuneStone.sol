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
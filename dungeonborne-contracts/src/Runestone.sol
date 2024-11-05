// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRuneStone.sol";

contract RuneStone is ERC1155, Ownable {
    // State variables
    mapping(uint256 => ElementType) private _elements;
    mapping(uint256 => PowerLevel) private _powerLevels;
    mapping(uint256 => bool) private _active;
    uint256 private _tokenIds;

    // Constants for URI construction
    string private constant BASE_URI = "https://game-uri.com/api/token/";
    
    constructor(address initialOwner) 
        ERC1155(string(abi.encodePacked(BASE_URI, "{id}.json")))
        Ownable(initialOwner)  // Explicitly set the initial owner
    {
        require(initialOwner != address(0), "RuneStone: zero address owner");
    }
    
    function mint(
        address to,
        ElementType element,
        PowerLevel power
    ) external onlyOwner returns (uint256) {
        require(to != address(0), "RuneStone: mint to zero address");
        
        uint256 newTokenId = _tokenIds++;
        _elements[newTokenId] = element;
        _powerLevels[newTokenId] = power;
        _active[newTokenId] = true;
        
        _mint(to, newTokenId, 1, "");
        
        emit RuneStoneCreated(newTokenId, element, power);
        return newTokenId;
    }
    
    function burn(uint256 tokenId) external {
        require(_exists(tokenId), "RuneStone: Invalid token ID");
        require(_active[tokenId], "RuneStone: Token not active");
        require(balanceOf(msg.sender, tokenId) > 0, "RuneStone: Not token owner");
        
        _burn(msg.sender, tokenId, 1);
        _active[tokenId] = false;
        
        emit RuneStoneUsed(tokenId, msg.sender);
    }
    
    function getRuneStoneDetails(uint256 tokenId) external view returns (
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

    // Optional: Override uri function if you need dynamic URI generation
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "RuneStone: URI query for nonexistent token");
        return string(abi.encodePacked(BASE_URI, _toString(tokenId), ".json"));
    }

    // Helper function to convert uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
        // Handle the case where value is 0
        if (value == 0) {
            return "0";
        }

        // Find the number of digits
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // Create the string
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    // Events (from IRuneStone)
    event RuneStoneCreated(uint256 indexed tokenId, ElementType element, PowerLevel power);
    event RuneStoneUsed(uint256 indexed tokenId, address indexed user);

    // Enums (from IRuneStone)
    enum ElementType { FIRE, WATER, EARTH, AIR, VOID }
    enum PowerLevel { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
}
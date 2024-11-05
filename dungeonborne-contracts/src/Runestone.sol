// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RuneStone is ERC1155, Ownable {
    using Strings for uint256;

    // Enums
    enum ElementType { FIRE, WATER, EARTH, AIR, LIGHTNING }
    enum PowerLevel { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

    // State variables
    uint256 private _currentTokenId;
    
    // Token mappings
    mapping(uint256 => RuneStoneDetails) private _runeStones;
    
    // Structs
    struct RuneStoneDetails {
        ElementType element;
        PowerLevel power;
        bool isActive;
    }

    // Events
    event RuneStoneCreated(uint256 indexed tokenId, ElementType element, PowerLevel power);
    event RuneStoneUsed(uint256 indexed tokenId, address indexed user);

    constructor(address initialOwner) 
        ERC1155("https://game-uri.com/api/token/{id}.json") 
        Ownable(initialOwner) 
    {}

    /**
     * @notice Mint a new RuneStone token
     * @param to Address to mint the token to
     * @param element Element type of the RuneStone
     * @param power Power level of the RuneStone
     * @return tokenId The ID of the newly minted token
     */
    function mint(
        address to,
        ElementType element,
        PowerLevel power
    ) external onlyOwner returns (uint256) {
        require(to != address(0), "RuneStone: mint to zero address");

        uint256 tokenId = _currentTokenId++;
        
        _runeStones[tokenId] = RuneStoneDetails({
            element: element,
            power: power,
            isActive: true
        });

        _mint(to, tokenId, 1, "");

        emit RuneStoneCreated(tokenId, element, power);
        
        return tokenId;
    }

    /**
     * @notice Burn a RuneStone token
     * @param tokenId ID of the token to burn
     */
    function burn(uint256 tokenId) external {
        require(_exists(tokenId), "RuneStone: Invalid token ID");
        require(_runeStones[tokenId].isActive, "RuneStone: Token not active");
        require(balanceOf(msg.sender, tokenId) > 0, "RuneStone: Not token owner");

        _burn(msg.sender, tokenId, 1);
        _runeStones[tokenId].isActive = false;

        emit RuneStoneUsed(tokenId, msg.sender);
    }

    /**
     * @notice Get the details of a RuneStone
     * @param tokenId ID of the token to query
     * @return element The element type of the RuneStone
     * @return power The power level of the RuneStone
     * @return isActive Whether the RuneStone is still active
     */
    function getRuneStoneDetails(uint256 tokenId) 
        external 
        view 
        returns (
            ElementType element,
            PowerLevel power,
            bool isActive
        ) 
    {
        require(_exists(tokenId), "RuneStone: Invalid token ID");
        RuneStoneDetails memory details = _runeStones[tokenId];
        return (details.element, details.power, details.isActive);
    }

    /**
     * @notice Override the URI function to check for token existence
     * @param tokenId ID of the token to get URI for
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "RuneStone: URI query for nonexistent token");
        return string(
            abi.encodePacked(
                "https://game-uri.com/api/token/",
                _toString(tokenId),
                ".json"
            )
        );
    }

    /**
     * @notice Check if a token exists
     * @param tokenId ID of the token to check
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentTokenId;
    }

    /**
     * @dev Internal function to convert a uint256 to its string representation
     * @param value The uint256 to convert
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
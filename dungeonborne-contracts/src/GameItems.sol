// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts//contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts//contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts//contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "../lib/openzeppelin-contracts//contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "../lib/openzeppelin-contracts//contracts/utils/Strings.sol";

contract GameItems is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Strings for uint256;

    // Item types
    enum ItemType { WEAPON, ARMOR, POTION, SCROLL }

    // Item rarity
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

    struct Item {
        string name;
        ItemType itemType;
        Rarity rarity;
        uint8 level;
        uint256[] convertibleToRunes; // Rune IDs this item can be converted into
        uint256[] runeAmounts; // Amount of each rune received when crushed
        bool isActive;
    }

    // Mapping from token ID to Item data
    mapping(uint256 => Item) public items;
    
    // Authorized minters (Game Engine contract)
    mapping(address => bool) public authorizedMinters;
    
    // Authorized crushers (Rune Crusher contract)
    mapping(address => bool) public authorizedCrushers;

    // Events
    event ItemCreated(
        uint256 indexed id, 
        string name, 
        ItemType itemType, 
        Rarity rarity,
        uint8 level
    );
    event ItemCrushed(
        uint256 indexed itemId,
        address indexed owner,
        uint256[] runeIds,
        uint256[] amounts
    );
    event MinterAuthorized(address indexed minter, bool status);
    event CrusherAuthorized(address indexed crusher, bool status);

    constructor() ERC1155("ipfs://YOUR_BASE_URI/") Ownable(msg.sender) {}

    // Modifiers
    modifier onlyMinter() {
        require(authorizedMinters[msg.sender] || owner() == msg.sender, "GameItems: Not authorized to mint");
        _;
    }

    modifier onlyCrusher() {
        require(authorizedCrushers[msg.sender] || owner() == msg.sender, "GameItems: Not authorized to crush");
        _;
    }

    // Admin functions
    function setMinter(address minter, bool status) external onlyOwner {
        authorizedMinters[minter] = status;
        emit MinterAuthorized(minter, status);
    }

    function setCrusher(address crusher, bool status) external onlyOwner {
        authorizedCrushers[crusher] = status;
        emit CrusherAuthorized(crusher, status);
    }

    function createItem(
        uint256 tokenId,
        string memory name,
        ItemType itemType,
        Rarity rarity,
        uint8 level,
        uint256[] memory convertibleToRunes,
        uint256[] memory runeAmounts
    ) external onlyOwner {
        require(!items[tokenId].isActive, "GameItems: Item already exists");
        require(bytes(name).length > 0, "GameItems: Name cannot be empty");
        require(convertibleToRunes.length == runeAmounts.length, "GameItems: Array lengths must match");
        
        items[tokenId] = Item({
            name: name,
            itemType: itemType,
            rarity: rarity,
            level: level,
            convertibleToRunes: convertibleToRunes,
            runeAmounts: runeAmounts,
            isActive: true
        });

        emit ItemCreated(tokenId, name, itemType, rarity, level);
    }

    // Minting functions
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external onlyMinter {
        require(items[tokenId].isActive, "GameItems: Item does not exist");
        _mint(to, tokenId, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyMinter {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(items[tokenIds[i]].isActive, "GameItems: Item does not exist");
        }
        _mintBatch(to, tokenIds, amounts, data);
    }

    // Crushing related functions
    function getCrushingResult(uint256 tokenId) 
        external 
        view 
        returns (uint256[] memory runeIds, uint256[] memory amounts) 
    {
        require(items[tokenId].isActive, "GameItems: Item does not exist");
        return (
            items[tokenId].convertibleToRunes,
            items[tokenId].runeAmounts
        );
    }

    function crush(address owner, uint256 tokenId, uint256 amount) 
        external 
        onlyCrusher 
        returns (uint256[] memory runeIds, uint256[] memory amounts) 
    {
        require(items[tokenId].isActive, "GameItems: Item does not exist");
        require(balanceOf(owner, tokenId) >= amount, "GameItems: Insufficient balance");

        // Calculate total rune amounts
        uint256[] memory totalAmounts = new uint256[](items[tokenId].runeAmounts.length);
        for (uint256 i = 0; i < items[tokenId].runeAmounts.length; i++) {
            totalAmounts[i] = items[tokenId].runeAmounts[i] * amount;
        }

        // Burn the items
        _burn(owner, tokenId, amount);

        emit ItemCrushed(
            tokenId,
            owner,
            items[tokenId].convertibleToRunes,
            totalAmounts
        );

        return (items[tokenId].convertibleToRunes, totalAmounts);
    }

    // View functions
    function getItem(uint256 tokenId) external view returns (Item memory) {
        require(items[tokenId].isActive, "GameItems: Item does not exist");
        return items[tokenId];
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(items[tokenId].isActive, "GameItems: URI query for nonexistent token");
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }

    // Required overrides
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
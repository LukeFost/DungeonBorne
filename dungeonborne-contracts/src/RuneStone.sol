// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts//contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts//contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts//contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "../lib/openzeppelin-contracts//contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract RuneStonesOfPower is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Strings for uint256;

    // Rune stone details
    struct RuneStone {
        string name;
        uint8 power;
        uint8 element; // 0: Fire, 1: Water, 2: Earth, 3: Air
        bool isActive;
    }

    // Mapping from token ID to RuneStone data
    mapping(uint256 => RuneStone) public runeStones;
    
    // Authorized minters (Fountain and Crusher contracts)
    mapping(address => bool) public authorizedMinters;
    
    // Events
    event RuneStoneCreated(uint256 indexed id, string name, uint8 power, uint8 element);
    event MinterAuthorized(address indexed minter, bool status);

    constructor() ERC1155("ipfs://YOUR_BASE_URI/") Ownable(msg.sender) {
        // Initialize with no rune stones
    }

    // Modifier for authorized minters
    modifier onlyMinter() {
        if (!authorizedMinters[msg.sender] && msg.sender != owner()) {
            revert("RuneStonesOfPower: Not authorized to mint");
        }
        _;
    }

    // Admin functions
    function setMinter(address minter, bool status) external onlyOwner {
        authorizedMinters[minter] = status;
        emit MinterAuthorized(minter, status);
    }

    function createRuneStone(
        uint256 tokenId,
        string memory name,
        uint8 power,
        uint8 element
    ) external onlyOwner {
        require(!runeStones[tokenId].isActive, "RuneStonesOfPower: Rune stone already exists");
        require(element <= 3, "RuneStonesOfPower: Invalid element type");
        require(bytes(name).length > 0, "RuneStonesOfPower: Name cannot be empty");
        
        runeStones[tokenId] = RuneStone({
            name: name,
            power: power,
            element: element,
            isActive: true
        });

        emit RuneStoneCreated(tokenId, name, power, element);
    }

    // Minting function
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external {
        // Ensure only authorized minters can mint
        if (!authorizedMinters[msg.sender] && msg.sender != owner()) {
            revert("RuneStonesOfPower: Not authorized to mint");
        }
        
        // Check if rune stone exists
        if (!runeStones[tokenId].isActive) {
            revert("RuneStonesOfPower: Rune stone does not exist");
        }
        
        _mint(to, tokenId, amount, data);
    }

    // Batch minting function
    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        // Ensure only authorized minters can mint
        if (!authorizedMinters[msg.sender] && msg.sender != owner()) {
            revert("RuneStonesOfPower: Not authorized to mint");
        }
        
        // Check if all rune stones exist
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!runeStones[tokenIds[i]].isActive) {
                revert("RuneStonesOfPower: Rune stone does not exist");
            }
        }
        
        _mintBatch(to, tokenIds, amounts, data);
    }

    // View functions
    function getRuneStone(uint256 tokenId) external view returns (RuneStone memory) {
        require(runeStones[tokenId].isActive, "RuneStonesOfPower: Rune stone does not exist");
        return runeStones[tokenId];
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if (!runeStones[tokenId].isActive) {
            revert("RuneStonesOfPower: URI query for nonexistent token");
        }
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

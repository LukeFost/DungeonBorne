// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RuneStone.sol";
import "../src/GameItems.sol";
import "../src/RuneCrusher.sol";

contract DeployRSPGame is Script {
    // Configuration struct for initial setup
    struct DeployConfig {
        address owner;
        address feeCollector;
        uint256 crushingFee;
        string baseUri;
    }

    // Initial rune stone configurations
    struct RuneConfig {
        uint256 id;
        string name;
        uint8 power;
        uint8 element;
    }

    // Initial item configurations
    struct ItemConfig {
        uint256 id;
        string name;
        uint8 itemType;
        uint8 rarity;
        uint8 level;
        uint256[] convertibleToRunes;
        uint256[] runeAmounts;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Load configuration
        DeployConfig memory config = getDeployConfig();
        RuneConfig[] memory runeConfigs = getInitialRuneConfigs();
        ItemConfig[] memory itemConfigs = getInitialItemConfigs();

        // Deploy contracts
        RuneStonesOfPower runeStones = new RuneStonesOfPower();
        GameItems gameItems = new GameItems();
        RuneCrusher runeCrusher = new RuneCrusher(
            address(runeStones),
            address(gameItems),
            config.feeCollector,
            config.crushingFee
        );

        // Setup initial rune stones
        for (uint256 i = 0; i < runeConfigs.length; i++) {
            runeStones.createRuneStone(
                runeConfigs[i].id,
                runeConfigs[i].name,
                runeConfigs[i].power,
                runeConfigs[i].element
            );
        }

        // Setup initial items
        for (uint256 i = 0; i < itemConfigs.length; i++) {
            gameItems.createItem(
                itemConfigs[i].id,
                itemConfigs[i].name,
                GameItems.ItemType(itemConfigs[i].itemType),
                GameItems.Rarity(itemConfigs[i].rarity),
                itemConfigs[i].level,
                itemConfigs[i].convertibleToRunes,
                itemConfigs[i].runeAmounts
            );
        }

        // Set up permissions
        runeStones.setMinter(address(runeCrusher), true);
        gameItems.setCrusher(address(runeCrusher), true);

        // Transfer ownership if needed
        if (config.owner != address(0)) {
            runeStones.transferOwnership(config.owner);
            gameItems.transferOwnership(config.owner);
            runeCrusher.transferOwnership(config.owner);
        }

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("Deployed Addresses:");
        console.log("RuneStonesOfPower:", address(runeStones));
        console.log("GameItems:", address(gameItems));
        console.log("RuneCrusher:", address(runeCrusher));
    }

    function getDeployConfig() internal view returns (DeployConfig memory) {
        return DeployConfig({
            owner: vm.envAddress("GAME_OWNER"),
            feeCollector: vm.envAddress("FEE_COLLECTOR"),
            crushingFee: vm.envUint("CRUSHING_FEE"),
            baseUri: vm.envString("BASE_URI")
        });
    }

    function getInitialRuneConfigs() internal pure returns (RuneConfig[] memory) {
        RuneConfig[] memory configs = new RuneConfig[](8);
        
        // Fire Runes
        configs[0] = RuneConfig(1, "Lesser Fire Rune", 5, 0);
        configs[1] = RuneConfig(2, "Greater Fire Rune", 10, 0);
        
        // Water Runes
        configs[2] = RuneConfig(3, "Lesser Water Rune", 5, 1);
        configs[3] = RuneConfig(4, "Greater Water Rune", 10, 1);
        
        // Earth Runes
        configs[4] = RuneConfig(5, "Lesser Earth Rune", 5, 2);
        configs[5] = RuneConfig(6, "Greater Earth Rune", 10, 2);
        
        // Air Runes
        configs[6] = RuneConfig(7, "Lesser Air Rune", 5, 3);
        configs[7] = RuneConfig(8, "Greater Air Rune", 10, 3);

        return configs;
    }

    function getInitialItemConfigs() internal pure returns (ItemConfig[] memory) {
        ItemConfig[] memory configs = new ItemConfig[](4);
        
        // Example: Fire Sword
        uint256[] memory runeIds1 = new uint256[](2);
        runeIds1[0] = 1; // Lesser Fire Rune
        runeIds1[1] = 2; // Greater Fire Rune
        
        uint256[] memory runeAmounts1 = new uint256[](2);
        runeAmounts1[0] = 2; // Get 2 Lesser Fire Runes
        runeAmounts1[1] = 1; // Get 1 Greater Fire Rune
        
        configs[0] = ItemConfig(
            1, // ID
            "Flame Sword",
            0, // WEAPON
            2, // RARE
            5, // Level
            runeIds1,
            runeAmounts1
        );

        // Example: Water Staff
        uint256[] memory runeIds2 = new uint256[](2);
        runeIds2[0] = 3; // Lesser Water Rune
        runeIds2[1] = 4; // Greater Water Rune
        
        uint256[] memory runeAmounts2 = new uint256[](2);
        runeAmounts2[0] = 2;
        runeAmounts2[1] = 1;
        
        configs[1] = ItemConfig(
            2,
            "Tide Staff",
            0, // WEAPON
            3, // EPIC
            10,
            runeIds2,
            runeAmounts2
        );

        // Add more initial items as needed...

        return configs;
    }
}
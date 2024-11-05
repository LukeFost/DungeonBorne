// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts//contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts//contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts//contracts/utils/Pausable.sol";
import "../lib/openzeppelin-contracts//contracts/utils/math/Math.sol";
import "./RuneStone.sol";

contract RuneFountain is Ownable, ReentrancyGuard, Pausable {
    using Math for uint256;

    // Contract references
    RuneStonesOfPower public immutable runeStones;
    
    // Price configuration
    struct PriceConfig {
        uint256 basePrice;      // Base price in wei
        uint256 maxPrice;       // Maximum price in wei
        uint256 priceIncrease;  // Price increase per purchase (percentage with 2 decimals, e.g., 500 = 5%)
        uint256 decayRate;      // Price decay per block (percentage with 2 decimals)
        uint256 lastPurchase;   // Block number of last purchase
        uint256 currentPrice;   // Current price including dynamic adjustments
        bool isActive;          // Whether this rune can be purchased
    }
    
    // Mappings
    mapping(uint256 => PriceConfig) public runePrices;  // Rune ID => Price Configuration
    mapping(address => uint256) public lastPurchaseBlock; // User => Block number of last purchase
    
    // Purchase limits
    uint256 public purchaseCooldown = 10 minutes;  // Time required between purchases
    uint256 public maxPurchaseAmount = 10;         // Maximum runes per purchase
    
    // Treasury
    address public treasury;
    uint256 public treasuryFee = 500;  // 5% fee (basis points)
    
    // Events
    event RunePriceUpdated(uint256 indexed runeId, uint256 newPrice);
    event RunePurchased(
        address indexed buyer,
        uint256 indexed runeId,
        uint256 amount,
        uint256 price,
        uint256 totalCost
    );
    event PriceConfigSet(
        uint256 indexed runeId,
        uint256 basePrice,
        uint256 maxPrice,
        uint256 priceIncrease,
        uint256 decayRate
    );
    event TreasuryUpdated(address newTreasury);
    event TreasuryFeeUpdated(uint256 newFee);
    event FundsWithdrawn(address treasury, uint256 amount);

    constructor(
        address _runeStones,
        address _treasury
    ) Ownable(msg.sender) {
        require(_runeStones != address(0), "RuneFountain: Invalid rune stones address");
        require(_treasury != address(0), "RuneFountain: Invalid treasury address");
        
        runeStones = RuneStonesOfPower(_runeStones);
        treasury = _treasury;
    }

    // Admin functions
    function setPriceConfig(
        uint256 runeId,
        uint256 basePrice,
        uint256 maxPrice,
        uint256 priceIncrease,
        uint256 decayRate
    ) external onlyOwner {
        require(basePrice > 0, "RuneFountain: Base price must be greater than 0");
        require(maxPrice >= basePrice, "RuneFountain: Max price must be >= base price");
        require(priceIncrease <= 10000, "RuneFountain: Price increase must be <= 100%");
        require(decayRate <= 10000, "RuneFountain: Decay rate must be <= 100%");
        
        runePrices[runeId] = PriceConfig({
            basePrice: basePrice,
            maxPrice: maxPrice,
            priceIncrease: priceIncrease,
            decayRate: decayRate,
            lastPurchase: block.number,
            currentPrice: basePrice,
            isActive: true
        });
        
        emit PriceConfigSet(runeId, basePrice, maxPrice, priceIncrease, decayRate);
    }
    
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "RuneFountain: Invalid treasury address");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }
    
    function setTreasuryFee(uint256 newFee) external onlyOwner {
        require(newFee <= 2000, "RuneFountain: Fee cannot exceed 20%");
        treasuryFee = newFee;
        emit TreasuryFeeUpdated(newFee);
    }
    
    function setPurchaseLimits(
        uint256 newCooldown,
        uint256 newMaxAmount
    ) external onlyOwner {
        purchaseCooldown = newCooldown;
        maxPurchaseAmount = newMaxAmount;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }

    // Price calculation functions
    function calculateCurrentPrice(uint256 runeId) public view returns (uint256) {
        PriceConfig memory config = runePrices[runeId];
        if (!config.isActive) return 0;
        
        uint256 blocksPassed = block.number - config.lastPurchase;
        uint256 decayedPrice = config.currentPrice;
        
        // Apply decay
        if (blocksPassed > 0 && config.decayRate > 0) {
            uint256 decay = (config.currentPrice * config.decayRate * blocksPassed) / 10000;
            decayedPrice = Math.max(config.basePrice, config.currentPrice - decay);
        }
        
        return decayedPrice;
    }
    
    function calculateTotalCost(
        uint256 runeId,
        uint256 amount
    ) public view returns (uint256 totalCost, uint256 averagePrice) {
        require(amount > 0, "RuneFountain: Amount must be greater than 0");
        require(amount <= maxPurchaseAmount, "RuneFountain: Exceeds max purchase amount");
        
        PriceConfig memory config = runePrices[runeId];
        require(config.isActive, "RuneFountain: Rune not available");
        
        uint256 currentPrice = calculateCurrentPrice(runeId);
        totalCost = 0;
        
        // Calculate progressive pricing
        for (uint256 i = 0; i < amount; i++) {
            uint256 itemPrice = Math.min(
                config.maxPrice,
                currentPrice + ((currentPrice * config.priceIncrease * i) / 10000)
            );
            totalCost += itemPrice;
        }
        
        averagePrice = totalCost / amount;
    }

    // Purchase function
    function purchaseRunes(
        uint256 runeId,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        require(
            block.timestamp >= lastPurchaseBlock[msg.sender] + purchaseCooldown,
            "RuneFountain: Purchase on cooldown"
        );
        
        (uint256 totalCost, ) = calculateTotalCost(runeId, amount);
        require(msg.value >= totalCost, "RuneFountain: Insufficient payment");
        
        // Update price state
        PriceConfig storage config = runePrices[runeId];
        config.lastPurchase = block.number;
        config.currentPrice = Math.min(
            config.maxPrice,
            config.currentPrice + ((config.currentPrice * config.priceIncrease) / 10000)
        );
        
        // Mint runes
        runeStones.mint(msg.sender, runeId, amount, "");
        
        // Update purchase timestamp
        lastPurchaseBlock[msg.sender] = block.timestamp;
        
        // Handle treasury fee
        uint256 feeAmount = (totalCost * treasuryFee) / 10000;
        if (feeAmount > 0) {
            (bool success, ) = treasury.call{value: feeAmount}("");
            require(success, "RuneFountain: Treasury fee transfer failed");
        }
        
        // Return excess payment
        uint256 excess = msg.value - totalCost;
        if (excess > 0) {
            (bool success, ) = msg.sender.call{value: excess}("");
            require(success, "RuneFountain: Excess return failed");
        }
        
        emit RunePurchased(msg.sender, runeId, amount, config.currentPrice, totalCost);
    }

    // View functions
    function getTimeUntilNextPurchase(address user) external view returns (uint256) {
        uint256 nextPurchaseTime = lastPurchaseBlock[user] + purchaseCooldown;
        if (block.timestamp >= nextPurchaseTime) return 0;
        return nextPurchaseTime - block.timestamp;
    }

    // Required to receive ETH
    receive() external payable {}
}
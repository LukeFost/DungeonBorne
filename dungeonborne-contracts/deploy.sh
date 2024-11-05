#!/bin/bash

# Load environment variables
source .env

# Check if we're deploying to testnet or mainnet
NETWORK=$1
if [ "$NETWORK" = "mainnet" ]; then
    echo "Deploying to Base mainnet..."
    NETWORK_ARGS="--rpc-url $RPC_URL"
elif [ "$NETWORK" = "testnet" ]; then
    echo "Deploying to Base Sepolia testnet..."
    NETWORK_ARGS="--rpc-url https://sepolia.base.org"
else
    echo "Please specify network: ./deploy.sh [mainnet|testnet]"
    exit 1
fi

# Run forge script
forge script script/DeployRSPGame.s.sol:DeployRSPGame \
    $NETWORK_ARGS \
    --broadcast \
    --verify \
    -vvvv

# Store deployment addresses
echo "Storing deployment addresses..."
grep "Deployed Addresses:" -A 3 broadcast/DeployRSPGame.s.sol/*/run-latest.json > deployed_addresses.txt
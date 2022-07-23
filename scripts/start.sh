#!/bin/bash

npx hardhat run ./scripts/deployScripts/ORFI.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/TreasuryHelper.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Treasury.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/TAVCalculator.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/sORFI.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Staking.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Bonding.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/RewardDistributor.ts --network oasis_mainnet
npx hardhat run ./scripts/deployScripts/LpAsset.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/LpManager.ts --network oasis_mainnet
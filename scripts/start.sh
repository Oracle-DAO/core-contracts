#!/bin/bash

npx hardhat run ./deployScripts/ORCL.ts --network oasis &&
npx hardhat run ./deployScripts/MIM.ts --network oasis &&
npx hardhat run ./deployScripts/TreasuryHelper.ts --network oasis &&
npx hardhat run ./deployScripts/Treasury.ts --network oasis &&
npx hardhat run ./deployScripts/TAVCalculator.ts --network oasis &&
npx hardhat run ./deployScripts/sORCL.ts --network oasis &&
npx hardhat run ./deployScripts/Staking.ts --network oasis &&
npx hardhat run ./deployScripts/Bonding.ts --network oasis &&
npx hardhat run ./deployScripts/RewardDistributor.ts --network oasis &&
npx hardhat run ./deployScripts/initialize.ts --network oasis
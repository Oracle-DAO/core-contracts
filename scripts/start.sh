#!/bin/bash

npx hardhat run ./deployScripts/ORFI.ts --network localhost &&
npx hardhat run ./deployScripts/MIM.ts --network localhost &&
npx hardhat run ./deployScripts/TreasuryHelper.ts --network localhost &&
npx hardhat run ./deployScripts/Treasury.ts --network localhost &&
npx hardhat run ./deployScripts/TAVCalculator.ts --network localhost &&
npx hardhat run ./deployScripts/sORFI.ts --network localhost &&
npx hardhat run ./deployScripts/Staking.ts --network localhost &&
npx hardhat run ./deployScripts/Bonding.ts --network localhost &&
npx hardhat run ./deployScripts/RewardDistributor.ts --network localhost &&
npx hardhat run ./deployScripts/initialize.ts --network localhost
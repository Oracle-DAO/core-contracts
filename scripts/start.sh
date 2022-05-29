#!/bin/bash

npx hardhat run ./deployScripts/ORFI.ts --network matic &&
npx hardhat run ./deployScripts/MIM.ts --network matic &&
npx hardhat run ./deployScripts/TreasuryHelper.ts --network matic &&
npx hardhat run ./deployScripts/Treasury.ts --network matic &&
npx hardhat run ./deployScripts/TAVCalculator.ts --network matic &&
npx hardhat run ./deployScripts/sORFI.ts --network matic &&
npx hardhat run ./deployScripts/Staking.ts --network matic &&
npx hardhat run ./deployScripts/Bonding.ts --network matic &&
npx hardhat run ./deployScripts/RewardDistributor.ts --network matic &&
npx hardhat run ./deployScripts/initialize.ts --network matic
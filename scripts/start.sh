#!/bin/bash

npx hardhat run ./deployScripts/ORCL.ts --network metis
npx hardhat run ./deployScripts/MIM.ts --network metis &&
npx hardhat run ./deployScripts/TreasuryHelper.ts --network metis &&
npx hardhat run ./deployScripts/Treasury.ts --network metis &&
npx hardhat run ./deployScripts/TAVCalculator.ts --network metis &&
npx hardhat run ./deployScripts/sORCL.ts --network metis &&
npx hardhat run ./deployScripts/Staking.ts --network metis &&
npx hardhat run ./deployScripts/Bonding.ts --network metis &&
npx hardhat run ./deployScripts/initialize.ts --network metis
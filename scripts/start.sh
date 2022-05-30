#!/bin/bash

npx hardhat run ./scripts/deployScripts/ORFI.ts --network metis &&
npx hardhat run ./scripts/deployScripts/MIM.ts --network metis &&
npx hardhat run ./scripts/deployScripts/TreasuryHelper.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Treasury.ts --network metis &&
npx hardhat run ./scripts/deployScripts/TAVCalculator.ts --network metis &&
npx hardhat run ./scripts/deployScripts/sORFI.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Staking.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Bonding.ts --network metis &&
npx hardhat run ./scripts/deployScripts/RewardDistributor.ts --network metis
#npx hardhat run ./scripts/deployScripts/LpAsset.ts --network metis &&
#npx hardhat run ./scripts/deployScripts/LpManager.ts --network metis
#!/bin/bash

npx hardhat run ./scripts/deployScripts/ORFI.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/TreasuryHelper.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/Treasury.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/TAVCalculator.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/sORFI.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/Staking.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/Bonding.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/RewardDistributor.ts --network polygon
#npx hardhat run ./scripts/deployScripts/LpAsset.ts --network polygon &&
#npx hardhat run ./scripts/deployScripts/LpManager.ts --network polygon
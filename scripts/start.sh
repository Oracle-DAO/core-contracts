#!/bin/bash

npx hardhat run ./scripts/deployScripts/CHRF.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/TreasuryHelper.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/Treasury.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/TAVCalculator.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/sCHRF.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/Staking.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/Bonding.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/RewardDistributor.ts --network bttc_testnet
#npx hardhat run ./scripts/deployScripts/LpAsset.ts --network bttc_testnet &&
#npx hardhat run ./scripts/deployScripts/LpManager.ts --network bttc_testnet
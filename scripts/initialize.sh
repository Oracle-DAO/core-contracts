#!/bin/bash

npx hardhat run ./scripts/deployScripts/Initialize/orfi.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Initialize/mim.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Initialize/bond.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Initialize/treasuryHelper.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Initialize/treasury.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Initialize/sORFI.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Initialize/staking.ts --network oasis_mainnet &&
npx hardhat run ./scripts/deployScripts/Initialize/rewardDistributor.ts --network oasis_mainnet
#npx hardhat run ./scripts/deployScripts/Initialize/lpManager.ts --network oasis_mainnet
#!/bin/bash

npx hardhat run ./scripts/deployScripts/Initialize/orfi.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Initialize/mim.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Initialize/bond.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Initialize/treasuryHelper.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Initialize/treasury.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Initialize/sORFI.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Initialize/staking.ts --network metis &&
npx hardhat run ./scripts/deployScripts/Initialize/rewardDistributor.ts --network metis
#npx hardhat run ./scripts/deployScripts/Initialize/lpManager.ts --network metis
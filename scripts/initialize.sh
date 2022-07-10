#!/bin/bash

#npx hardhat run ./scripts/deployScripts/Initialize/orfi.ts --network polygon &&
#npx hardhat run ./scripts/deployScripts/Initialize/mim.ts --network polygon &&
#npx hardhat run ./scripts/deployScripts/Initialize/bond.ts --network polygon &&
#npx hardhat run ./scripts/deployScripts/Initialize/treasuryHelper.ts --network polygon &&
#npx hardhat run ./scripts/deployScripts/Initialize/treasury.ts --network polygon &&
#npx hardhat run ./scripts/deployScripts/Initialize/sORFI.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/Initialize/staking.ts --network polygon &&
npx hardhat run ./scripts/deployScripts/Initialize/rewardDistributor.ts --network polygon
#npx hardhat run ./scripts/deployScripts/Initialize/lpManager.ts --network polygon
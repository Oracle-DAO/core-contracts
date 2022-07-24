#!/bin/bash

#npx hardhat run ./scripts/deployScripts/Initialize/chrf.ts --network bttc_testnet &&
#npx hardhat run ./scripts/deployScripts/Initialize/mim.ts --network bttc_testnet &&
#npx hardhat run ./scripts/deployScripts/Initialize/bond.ts --network bttc_testnet &&
#npx hardhat run ./scripts/deployScripts/Initialize/treasuryHelper.ts --network bttc_testnet
npx hardhat run ./scripts/deployScripts/Initialize/treasury.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/Initialize/sCHRF.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/Initialize/staking.ts --network bttc_testnet &&
npx hardhat run ./scripts/deployScripts/Initialize/rewardDistributor.ts --network bttc_testnet
#npx hardhat run ./scripts/deployScripts/Initialize/lpManager.ts --network bttc_testnet
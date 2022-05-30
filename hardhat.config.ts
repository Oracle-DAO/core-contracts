import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    polygon: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/-uRy8IMZxGnHG4EeeXSfBxzdjFxac4j4",
      accounts:
        process.env.PREPROD_PRIVATE_KEY !== undefined ? [process.env.PREPROD_PRIVATE_KEY] : [],
    },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com/v1/359ff5efa8f5b3f88dda7197b743de8312f31344",
      accounts:
        process.env.TEST_PTIVATE_KEY !== undefined
          ? [process.env.TEST_PTIVATE_KEY]
          : [],
    },
    metis: {
      url: "https://stardust.metis.io/?owner=588",
      accounts:
          process.env.TEST_PTIVATE_KEY !== undefined && process.env.TEAM_FEES_PRIVATE_KEY !== undefined ? [process.env.TEST_PTIVATE_KEY, process.env.TEAM_FEES_PRIVATE_KEY] : [],
    },
    oasis: {
      url: "https://testnet.emerald.oasis.dev",
      accounts:
        process.env.TEST_PTIVATE_KEY !== undefined && process.env.TEAM_FEES_PRIVATE_KEY !== undefined ? [process.env.TEST_PTIVATE_KEY, process.env.TEAM_FEES_PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
};

export default config;

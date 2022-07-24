// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../helpers";

async function main() {
  const sCHRFAddress = readContractAddress("/StakedCHRF.json");
  const stakingAdd = readContractAddress("/Staking.json");

  const RewardDistributorFact = await ethers.getContractFactory(
    "RewardDistributor"
  );
  const rewardDistributor = await RewardDistributorFact.deploy(
    stakingAdd,
    sCHRFAddress
  );
  await rewardDistributor.deployed();

  console.log("Token address of rewardDistributor:", rewardDistributor.address);
  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(rewardDistributor, "RewardDistributor");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

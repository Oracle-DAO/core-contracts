// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../helpers";
import { constants } from "../constants";

const RewardDistributorAdd = readContractAddress("/RewardDistributor.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
  const rewardDistributor = await RewardDistributor.attach(RewardDistributorAdd);

  await rewardDistributor.completeRewardCycle("1000000000");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

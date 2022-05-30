// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";

const stakingAdd = readContractAddress("/Staking.json");
const RewardDistributorAdd = readContractAddress("/RewardDistributor.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.attach(stakingAdd);

  const RewardDistributor = await ethers.getContractFactory(
    "RewardDistributor"
  );
  const rewardDistributor = await RewardDistributor.attach(
    RewardDistributorAdd
  );

  await staking.setRewardDistributor(rewardDistributor.address);
  console.log("step 8");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

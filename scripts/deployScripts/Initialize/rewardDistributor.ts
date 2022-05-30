// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const mimAdd = readContractAddress("/MIM.json");
const treasuryAdd = readContractAddress("/Treasury.json");
const RewardDistributorAdd = readContractAddress("/RewardDistributor.json");

async function main() {
  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.attach(treasuryAdd);

  const MIM = await ethers.getContractFactory("MIM");
  const mim = await MIM.attach(mimAdd);

  const RewardDistributor = await ethers.getContractFactory(
    "RewardDistributor"
  );
  const rewardDistributor = await RewardDistributor.attach(
    RewardDistributorAdd
  );

  await rewardDistributor.setTreasuryAddress(treasury.address);
  console.log("step 1");

  await rewardDistributor.setStableCoinAddress(mim.address);
  console.log("step 2");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const bondAdd = readContractAddress("/Bond.json");
const TreasuryHelperAdd = readContractAddress("/TreasuryHelper.json");
const RewardDistributorAdd = readContractAddress("/RewardDistributor.json");

async function main() {
  const [deployer] = await ethers.getSigners();
  const MIMBond = await ethers.getContractFactory("Bond");
  const mimBond = await MIMBond.attach(bondAdd);

  const TreasuryHelper = await ethers.getContractFactory("TreasuryHelper");
  const treasuryHelper = await TreasuryHelper.attach(TreasuryHelperAdd);

  const RewardDistributor = await ethers.getContractFactory(
    "RewardDistributor"
  );
  const rewardDistributor = await RewardDistributor.attach(
    RewardDistributorAdd
  );

  // // bond depository address will go here
  // await treasuryHelper.queue("0", mimBond.address);
  // console.log("step 11");
  //
  // // bond depository address will go here
  // await treasuryHelper.toggle("0", mimBond.address, constants.zeroAddress);
  // console.log("step 12");
  //
  // // temporary deployer address for testing
  // await treasuryHelper.queue("0", deployer.address);
  // console.log("step 13");
  //
  // // temporary deployer address for testing
  // await treasuryHelper.toggle("0", deployer.address, constants.zeroAddress);
  // console.log("step 14");
  //
  // // reserve spender address will go here. They will burn ORFI. Only for testing
  // await treasuryHelper.queue("1", deployer.address);
  // console.log("step 15");
  //
  // // reserve spender address will go here
  // await treasuryHelper.toggle("1", deployer.address, constants.zeroAddress);
  // console.log("step 16");
  //
  // // reserve manager address will go here. They will allocate money using manage function in treasury. Gnosis will go here
  // await treasuryHelper.queue("3", deployer.address);
  // console.log("step 17");

  // reserve manager address will go here. They will allocate money
  await treasuryHelper.toggle("3", deployer.address, constants.zeroAddress);
  console.log("step 18");

  // reserve manager address will go here. They will allocate money
  await treasuryHelper.queue("3", rewardDistributor.address);
  console.log("step 19");

  // reserve manager address will go here. They will allocate money
  await treasuryHelper.toggle(
    "3",
    rewardDistributor.address,
    constants.zeroAddress
  );
  console.log("step 20");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

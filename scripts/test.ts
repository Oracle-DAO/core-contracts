// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "./helpers";
import {constants} from "./constants";

const sORFIAdd = readContractAddress("/StakedORFI.json");
const mimAdd = readContractAddress("/MIM.json");
const orfiAdd = readContractAddress("/ORFI.json");
const bondAdd = readContractAddress("/Bond.json");
const tavCalculatorAdd = readContractAddress("/TAVCalculator.json");
const stakingAdd = readContractAddress("/Staking.json");
const treasuryAdd = readContractAddress("/Treasury.json");
const TreasuryHelperAdd = readContractAddress("/TreasuryHelper.json");
const RewardDistributorAdd = readContractAddress("/RewardDistributor.json");
const LpManagerAdd = readContractAddress("/LpManager.json");
const LpAssetAdd = readContractAddress("/LpAsset.json");

async function main() {
  const [deployer] = await ethers.getSigners();
  const MIMBond = await ethers.getContractFactory("Bond");
  const mimBond = await MIMBond.attach(bondAdd);

  const ORFI = await ethers.getContractFactory("ORFI");
  const orfi = await ORFI.attach(orfiAdd);

  const StakedORFI = await ethers.getContractFactory("StakedORFI");
  const sORFI = await StakedORFI.attach(sORFIAdd);

  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.attach(treasuryAdd);

  const TreasuryHelper = await ethers.getContractFactory("TreasuryHelper");
  const treasuryHelper = await TreasuryHelper.attach(TreasuryHelperAdd);

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.attach(stakingAdd);

  const MIM = await ethers.getContractFactory("MIM");
  const mim = await MIM.attach(mimAdd);

  const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
  const tavCalculator = await TAVCalculator.attach(tavCalculatorAdd);

  const RewardDistributor = await ethers.getContractFactory(
    "RewardDistributor"
  );
  const rewardDistributor = await RewardDistributor.attach(
    RewardDistributorAdd
  );

  const LpAssetFact = await ethers.getContractFactory(
      "LpAsset"
  );
  const LpAsset = await LpAssetFact.attach(
      LpAssetAdd
  );

  // console.log(await mimBond.bondPrice());
  //
  // console.log(await mimBond.floorPriceValue());

  console.log(await rewardDistributor.getTotalStakedOrfiOfUserForACycle(deployer.address, 1));

  console.log(await rewardDistributor.rewardsForACycle(deployer.address, 1));

  console.log(await treasury.totalReserves());

  await mimBond.setAdjustment(true, 100, 3000, 100, 1);

  // await mimBond.setBondTerms(0, 2400);

  // await treasury.withdraw("1000000000", constants.principalToken);

  // console.log(await treasury.totalReserves());
  //
  // await staking.stake(deployer.address, "1000000000000000000000");
  //
  // console.log(await rewardDistributor.getTotalStakedOrfiOfUserForACycle(deployer.address, 1));
  //
  // await staking.unstake(deployer.address, "1000000000000000000000");
  //
  // console.log(await rewardDistributor.getTotalStakedOrfiOfUserForACycle(deployer.address, 1));

  // await mimBond.setFloorPriceValue(constants.floorPrice);
  //
  // console.log(await mimBond.bondPrice());
  //
  // console.log(await mimBond.terms());

  // console.log("tav : ", await tavCalculator.calculateTAV());
  //
  // console.log("total reserves of LP", await LpAsset.totalReserves());
  //
  // console.log("total reserves of Treasury", await treasury.totalReserves());
  //
  // console.log("total ORFI supply",await orfi.totalSupply());
  //
  // const terms = await mimBond.terms();
  //
  // console.log("terms fees:", terms.fee);
  // console.log("terms control variable:", terms.controlVariable);
  // console.log("debt ratio:", await mimBond.debtRatio());

  // const LpAssetFact1 = await ethers.getContractFactory(
  //     "LpAsset"
  // );
  // const LpAsset1 = await LpAssetFact1.deploy(
  //     constants.lpAddress, constants.principalToken
  // );
  //
  // await LpAsset1.deployed();
  //
  // console.log("address of LpAsset1", LpAsset1.address);
  //
  // console.log("total reserves of LP1", await LpAsset1.totalReserves());




  // console.log(await rewardDistributor.getTotalStakedOrfiOfUserForACycle(deployer.address, 1));

  // await orfi.setBaseSellTax(15);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

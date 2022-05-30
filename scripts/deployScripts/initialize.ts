// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../helpers";
import { constants } from "../constants";

const sORFIAdd = readContractAddress("/StakedORFI.json");
const mimAdd = readContractAddress("/MIM.json");
const orfiAdd = readContractAddress("/ORFI.json");
const bondAdd = readContractAddress("/Bond.json");
const tavCalculatorAdd = readContractAddress("/TAVCalculator.json");
const stakingAdd = readContractAddress("/Staking.json");
const treasuryAdd = readContractAddress("/Treasury.json");
const TreasuryHelperAdd = readContractAddress("/TreasuryHelper.json");
const RewardDistributorAdd = readContractAddress("/RewardDistributor.json");

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

  const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
  const rewardDistributor = await RewardDistributor.attach(RewardDistributorAdd);

  // await mimBond.initializeBondTerms(
  //   constants.mimBondBCV,
  //   constants.minBondPrice,
  //   constants.maxBondPayout,
  //   constants.minBondPayout,
  //   constants.bondFee,
  //   constants.bondRewardFee,
  //   constants.maxBondDebt,
  //   constants.bondVestingLength
  // );

  // await mimBond.setTAVCalculator(tavCalculator.address);
  // await mimBond.setStaking(staking.address);

  // await staking.setRewardDistributor(rewardDistributor.address);

  // TODO: mint ORFI and transfer it to NTT contract
  // await orfi.setVault(treasury.address);

  // await sORFI.initialize(staking.address);

  // // bond depository address will go here
  // await treasuryHelper.queue("0", mimBond.address);
  //
  // // bond depository address will go here
  // await treasuryHelper.toggle("0", mimBond.address, constants.zeroAddress);
  //
  // // temporary deployer address for testing
  // await treasuryHelper.queue("0", deployer.address);
  //
  // // temporary deployer address for testing
  // await treasuryHelper.toggle("0", deployer.address, constants.zeroAddress);
  //
  // // reserve spender address will go here. They will burn ORFI. Only for testing
  // await treasuryHelper.queue("1", deployer.address);
  //
  // // reserve spender address will go here
  // await treasuryHelper.toggle("1", deployer.address, constants.zeroAddress);
  //
  // // reserve manager address will go here. They will allocate money using manage function in treasury. Gnosis will go here
  // await treasuryHelper.queue("3", deployer.address);
  //
  // // reserve manager address will go here. They will allocate money
  // await treasuryHelper.toggle("3", deployer.address, constants.zeroAddress);
  //
  // // reserve manager address will go here. They will allocate money
  // await treasuryHelper.queue("3", rewardDistributor.address);
  //
  // // reserve manager address will go here. They will allocate money
  // await treasuryHelper.toggle("3", rewardDistributor.address, constants.zeroAddress);

  // approve large number for treasury, so that it can move
  // await mim.approve(treasury.address, constants.largeApproval);
  //
  // // approve large number for treasury, so that it can transfer token as spender
  // await mim.approve(mimBond.address, constants.largeApproval);

  // approve treasury address for a user so that treasury can burn orfi for user
  // await orfi.approve(treasury.address, constants.largeApproval);

  // await treasury.setTAVCalculator(tavCalculator.address);

  // mint mim for msg.sender. only for testing
  // await mim.mint(deployer.address, "10000000000000000000000000");

  // // Deposit 5,000,000 MIM and mint 5,000,000 ORFI
  // await treasury.deposit(
  //   "5000000000000000000000000", // reserve token amount to deposit
  //   mim.address,
  //   "5000000000000000000000000" // amount of orfi to mint
  // );

  // await rewardDistributor.setTreasuryAddress(treasury.address);

  // await rewardDistributor.setStableCoinAddress(mim.address);

  console.log("contracts are attached to their ABIs");
  console.log("ORFI: " + orfiAdd);
  console.log("MIM Token: " + mimAdd);
  console.log("Treasury: " + treasuryAdd);
  console.log("TreasuryHelper: " + TreasuryHelperAdd);
  console.log("TAV Calculator: " + tavCalculatorAdd);
  console.log("Staking: " + stakingAdd);
  console.log("sORFI: " + sORFIAdd);
  console.log("RewardDistributor: " + RewardDistributorAdd);
  console.log("MIM-ORFI Bond: " + mimBond.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

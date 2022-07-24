// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../helpers";
import { constants } from "../constants";

const sCHRFAdd = readContractAddress("/StakedCHRF.json");
const mimAdd = readContractAddress("/MIM.json");
const chrfAdd = readContractAddress("/CHRF.json");
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

  const CHRF = await ethers.getContractFactory("CHRF");
  const chrf = await CHRF.attach(chrfAdd);

  const StakedCHRF = await ethers.getContractFactory("StakedCHRF");
  const sCHRF = await StakedCHRF.attach(sCHRFAdd);

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

  // TODO: mint CHRF and transfer it to NTT contract
  // await chrf.setVault(treasury.address);

  // await sCHRF.initialize(staking.address);

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
  // // reserve spender address will go here. They will burn CHRF. Only for testing
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

  // approve treasury address for a user so that treasury can burn chrf for user
  // await chrf.approve(treasury.address, constants.largeApproval);

  // await treasury.setTAVCalculator(tavCalculator.address);

  // mint mim for msg.sender. only for testing
  // await mim.mint(deployer.address, "10000000000000000000000000");

  // // Deposit 5,000,000 MIM and mint 5,000,000 CHRF
  // await treasury.deposit(
  //   "5000000000000000000000000", // reserve token amount to deposit
  //   mim.address,
  //   "5000000000000000000000000" // amount of chrf to mint
  // );

  // await rewardDistributor.setTreasuryAddress(treasury.address);

  // await rewardDistributor.setStableCoinAddress(mim.address);

  console.log("contracts are attached to their ABIs");
  console.log("CHRF: " + chrfAdd);
  console.log("MIM Token: " + constants.usdtAddress);
  console.log("Treasury: " + treasuryAdd);
  console.log("TreasuryHelper: " + TreasuryHelperAdd);
  console.log("TAV Calculator: " + tavCalculatorAdd);
  console.log("Staking: " + stakingAdd);
  console.log("sCHRF: " + sCHRFAdd);
  console.log("RewardDistributor: " + RewardDistributorAdd);
  console.log("MIM-CHRF Bond: " + mimBond.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

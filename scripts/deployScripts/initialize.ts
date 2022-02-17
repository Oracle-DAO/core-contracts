// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../helpers";
import { constants } from "../constants";

const sORCLAdd = readContractAddress("/StakedORCL.json");
const mimAdd = readContractAddress("/MIM.json");
const orclAdd = readContractAddress("/ORCL.json");
const bondAdd = readContractAddress("/Bond.json");
const tavCalculatorAdd = readContractAddress("/TAVCalculator.json");
const stakingAdd = readContractAddress("/Staking.json");
const treasuryAdd = readContractAddress("/Treasury.json");
const TreasuryHelperAdd = readContractAddress("/TreasuryHelper.json");

async function main() {
  const [deployer] = await ethers.getSigners();
  const MIMBond = await ethers.getContractFactory("Bond");
  const mimBond = await MIMBond.attach(bondAdd);

  const ORCL = await ethers.getContractFactory("ORCL");
  const orcl = await ORCL.attach(orclAdd);

  const StakedORCL = await ethers.getContractFactory("StakedORCL");
  const sORCL = await StakedORCL.attach(sORCLAdd);

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

  await mimBond.initializeBondTerms(
    constants.mimBondBCV,
    constants.minBondPrice,
    constants.maxBondPayout,
    constants.minBondPayout,
    constants.bondFee,
    constants.maxBondDebt,
    constants.bondVestingLength
  );

  await mimBond.setTAVCalculator(tavCalculator.address);

  await orcl.setVault(treasury.address);

  await sORCL.initialize(staking.address);

  // bond depository address will go here
  await treasuryHelper.queue("0", mimBond.address);

  // bond depository address will go here
  await treasuryHelper.toggle("0", mimBond.address, constants.zeroAddress);

  // temporary deployer address for testing
  await treasuryHelper.queue("0", deployer.address);

  // temporary deployer address for testing
  await treasuryHelper.toggle("0", deployer.address, constants.zeroAddress);

  // reserve spender address will go here. They will burn ORCL
  await treasuryHelper.queue("1", deployer.address);

  // reserve spender address will go here
  await treasuryHelper.toggle("1", deployer.address, constants.zeroAddress);

  // reserve manager address will go here. They will allocate money
  await treasuryHelper.queue("3", deployer.address);

  // reserve manager address will go here. They will allocate money
  await treasuryHelper.toggle("3", deployer.address, constants.zeroAddress);

  // approve large number for treasury, so that it can move
  await mim.approve(treasury.address, constants.largeApproval);

  // approve large number for treasury, so that it can transfer token as spender
  await mim.approve(mimBond.address, constants.largeApproval);

  // approve treasury address for a user so that treasury can burn orcl for user
  await orcl.approve(treasury.address, constants.largeApproval);

  await treasury.setTAVCalculator(tavCalculator.address);

  // mint mim for msg.sender
  await mim.mint(deployer.address, "10000000000000000000000000");

  // Deposit 5,000,000 MIM and mint 5,000,000 ORCL
  await treasury.deposit(
    "5000000000000000000000000", // reserve token amount to deposit
    mim.address,
    "5000000000000000000000000" // amount of orcl to mint
  );

  console.log("contracts are attached to their ABIs");
  console.log("ORCL: " + orclAdd);
  console.log("MIM Token: " + mimAdd);
  console.log("Treasury: " + treasuryAdd);
  console.log("TreasuryHelper: " + TreasuryHelperAdd);
  console.log("TAV Calculator: " + tavCalculatorAdd);
  console.log("Staking: " + stakingAdd);
  console.log("sORCL: " + sORCLAdd);
  console.log("MIM-ORCL Bond: " + mimBond.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

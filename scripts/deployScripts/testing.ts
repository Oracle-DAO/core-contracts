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

  console.log(await sORCL.balanceOf(deployer.address));
  console.log(await orcl.balanceOf(deployer.address));
  const txn = await mimBond.redeem(deployer.address, true, {gasLimit: 2500000});
  txn.wait();
  console.log(await sORCL.balanceOf(deployer.address));
  console.log(await orcl.balanceOf(deployer.address));
  console.log(txn);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

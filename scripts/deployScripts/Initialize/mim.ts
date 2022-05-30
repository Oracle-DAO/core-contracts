// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const mimAdd = readContractAddress("/MIM.json");
const bondAdd = readContractAddress("/Bond.json");
const treasuryAdd = readContractAddress("/Treasury.json");

async function main() {
  const [deployer] = await ethers.getSigners();
  const MIMBond = await ethers.getContractFactory("Bond");
  const mimBond = await MIMBond.attach(bondAdd);

  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.attach(treasuryAdd);

  const MIM = await ethers.getContractFactory("MIM");
  const mim = await MIM.attach(mimAdd);

  // approve large number for treasury, so that it can move
  await mim.approve(treasury.address, constants.largeApproval);
  console.log("step 4");
  // approve large number for treasury, so that it can transfer token as spender
  await mim.approve(mimBond.address, constants.largeApproval);
  console.log("step 5");

  await mim.mint(deployer.address, "1000000000000");
  console.log("step 6");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const chrfAdd = readContractAddress("/CHRF.json");
const treasuryAdd = readContractAddress("/Treasury.json");

async function main() {
  const [deployer] = await ethers.getSigners();
  const CHRF = await ethers.getContractFactory("CHRF");
  const chrf = await CHRF.attach(chrfAdd);

  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.attach(treasuryAdd);

  await chrf.setVault(deployer.address);

  // await chrf.mint(constants.nttContractAddress, "181000000000000000000000");
  await chrf.mint(deployer.address, "100000000000000000000000");

  console.log("step 6");

  await chrf.setVault(treasury.address);
  console.log("vault set completed");

  // approve treasury address for a user so that treasury can burn chrf for user
  await chrf.approve(treasury.address, constants.largeApproval);
  console.log("chrf approve completed");

  await chrf.setBaseSellTax(0);
  console.log("sell tax value is 0");

  await chrf.setMultiplier(0);
  console.log("multiplier is 0");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

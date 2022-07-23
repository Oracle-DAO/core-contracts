// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const orfiAdd = readContractAddress("/ORFI.json");
const treasuryAdd = readContractAddress("/Treasury.json");

async function main() {
  const [deployer] = await ethers.getSigners();
  const ORFI = await ethers.getContractFactory("ORFI");
  const orfi = await ORFI.attach(orfiAdd);

  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.attach(treasuryAdd);

  await orfi.setVault(deployer.address);

  // await orfi.mint(constants.nttContractAddress, "181000000000000000000000");
  await orfi.mint(deployer.address, "100000000000000000000000");

  console.log("step 6");

  await orfi.setVault(treasury.address);
  console.log("vault set completed");

  // approve treasury address for a user so that treasury can burn orfi for user
  await orfi.approve(treasury.address, constants.largeApproval);
  console.log("orfi approve completed");

  await orfi.setBaseSellTax(0);
  console.log("sell tax value is 0");

  await orfi.setMultiplier(0);
  console.log("multiplier is 0");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

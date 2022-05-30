// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  const [deployer] = await ethers.getSigners();

  const ORFI = await ethers.getContractFactory("ORFI");
  const orfi = await ORFI.deploy();
  await orfi.deployed();

  console.log("Token address of orfi:", orfi.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(orfi, "ORFI");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

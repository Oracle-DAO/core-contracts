// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  const [deployer] = await ethers.getSigners();

  const CHRF = await ethers.getContractFactory("CHRF");
  const chrf = await CHRF.deploy();
  await chrf.deployed();

  console.log("Token address of chrf:", chrf.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(chrf, "CHRF");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

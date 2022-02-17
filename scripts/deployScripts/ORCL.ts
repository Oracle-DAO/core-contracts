// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.address
  );

  const ORCL = await ethers.getContractFactory("ORCL");
  const orcl = await ORCL.deploy();
  await orcl.deployed();

  console.log("Token address of orcl:", orcl.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(orcl, "ORCL");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

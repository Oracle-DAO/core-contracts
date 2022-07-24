// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../helpers";

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.address
  );

  const chrfAddress = readContractAddress("/CHRF.json");

  const ChrfFaucet = await ethers.getContractFactory("ChrfFaucet");
  const chrfFaucet = await ChrfFaucet.deploy(chrfAddress);
  await chrfFaucet.deployed();

  console.log("Token address of chrfFaucet:", chrfFaucet.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(chrfFaucet, "ChrfFaucet");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

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

  const orfiAddress = readContractAddress("/ORFI.json");

  const OrfiFaucet = await ethers.getContractFactory("OrfiFaucet");
  const orfiFaucet = await OrfiFaucet.deploy(orfiAddress);
  await orfiFaucet.deployed();

  console.log("Token address of orfiFaucet:", orfiFaucet.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(orfiFaucet, "OrfiFaucet");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

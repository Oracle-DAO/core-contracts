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

  const mimAddress = readContractAddress("/MIM.json");

  const MIMFaucet = await ethers.getContractFactory("MIMFaucet");
  const mimFaucet = await MIMFaucet.deploy(mimAddress);
  await mimFaucet.deployed();

  console.log("Token address of mimFaucet:", mimFaucet.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(mimFaucet, "MIMFaucet");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

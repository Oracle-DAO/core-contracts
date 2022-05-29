// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  const [deployer] = await ethers.getSigners();
  // console.log(
  //   "Deploying the contracts with the account:",
  //   await deployer.address
  // );

  const ORFI = await ethers.getContractFactory("ORFI");
  const orfi = await ORFI.deploy("0x68aF0143c88406e76FDF725c71842B7e42dfDb01");
  await orfi.deployed();

  console.log("Token address of orfi:", orfi.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(orfi, "ORFI");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

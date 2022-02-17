// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";
import { constants } from "../constants";

async function main() {
  const [deployer] = await ethers.getSigners();

  const MIM = await ethers.getContractFactory("MIM");
  const mim = await MIM.deploy();
  await mim.deployed();

  console.log("Token address of mim:", mim.address);

  await mim.mint(deployer.address, constants.initialMint);
  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(mim, "MIM");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

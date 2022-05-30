// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";

async function main() {
  const LpManagerFact = await ethers.getContractFactory("LpManager");
  const LpManager = await LpManagerFact.deploy();
  await LpManager.deployed();

  console.log("Token address of LpManager:", LpManager.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(LpManager, "LpManager");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

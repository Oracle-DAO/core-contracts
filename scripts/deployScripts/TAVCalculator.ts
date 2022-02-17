// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../helpers";
import { constants } from "../constants";

async function main() {
  // ethers is avaialble in the global scope
  const orclAddress = readContractAddress("/ORCL.json");
  const treasuryAddress = readContractAddress("/Treasury.json");

  const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
  const tavCalculator = await TAVCalculator.deploy(
    orclAddress,
    treasuryAddress
  );
  await tavCalculator.deployed();

  console.log("Token address for tavCalculator:", tavCalculator.address);
  saveFrontendFiles(tavCalculator, "TAVCalculator");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

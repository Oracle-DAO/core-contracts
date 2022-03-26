// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../helpers";
import { constants } from "../constants";

async function main() {
  // ethers is avaialble in the global scope
  const orfiAddress = readContractAddress("/ORFI.json");
  const mimAddress = readContractAddress("/mim.json");

  const TreasuryHelper = await ethers.getContractFactory("TreasuryHelper");
  const treasuryHelper = await TreasuryHelper.deploy(
    orfiAddress,
    mimAddress,
    constants.blockNeededToWait
  );
  await treasuryHelper.deployed();

  console.log("Token address of treasuryHelper:", treasuryHelper.address);
  saveFrontendFiles(treasuryHelper, "TreasuryHelper");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

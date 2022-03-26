// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../helpers";

async function main() {
  const orfiAddress = readContractAddress("/ORFI.json");
  const treasuryHelperAddress = readContractAddress("/TreasuryHelper.json");

  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy(orfiAddress, treasuryHelperAddress);
  await treasury.deployed();

  console.log("Token address of treasury:", treasury.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(treasury, "Treasury");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

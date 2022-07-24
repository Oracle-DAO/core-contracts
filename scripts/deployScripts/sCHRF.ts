// @ts-ignore
import { ethers} from "hardhat";
import { saveFrontendFiles } from "../helpers";

async function main() {
  const StakedCHRF = await ethers.getContractFactory("StakedCHRF");
  const sCHRF = await StakedCHRF.deploy();
  await sCHRF.deployed();

  console.log("Token address of sCHRF:", sCHRF.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(sCHRF, "StakedCHRF");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
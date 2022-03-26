// @ts-ignore
import { ethers} from "hardhat";
import { saveFrontendFiles } from "../helpers";

async function main() {
  const StakedORFI = await ethers.getContractFactory("StakedORFI");
  const sORFI = await StakedORFI.deploy();
  await sORFI.deployed();

  console.log("Token address of sORFI:", sORFI.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(sORFI, "StakedORFI");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
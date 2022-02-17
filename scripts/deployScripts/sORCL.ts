// @ts-ignore
import { ethers} from "hardhat";
import { saveFrontendFiles } from "../helpers";

async function main() {
  const StakedORCL = await ethers.getContractFactory("StakedORCL");
  const sORCL = await StakedORCL.deploy();
  await sORCL.deployed();

  console.log("Token address of sORCL:", sORCL.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(sORCL, "StakedORCL");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
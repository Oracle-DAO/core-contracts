// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";
import { constants } from "../constants";
import { address } from "hardhat/internal/core/config/config-validation";

async function main() {
  const [deployer] = await ethers.getSigners();

  const userAddress = "0xcC7d499d1903A6A4FaCC2665117C1485C66C6B3e";

  const NTT = await ethers.getContractFactory("NTT");
  const ntt = await NTT.deploy();
  await ntt.deployed();

  console.log("Address of ntt:", ntt.address);

  const ProjectManagement = await ethers.getContractFactory("ProjectManagement");
  const projectManagement = await ProjectManagement.deploy(ntt.address);
  await projectManagement.deployed();

  console.log("Address of project Management:", projectManagement.address);

  await ntt.approveAddressForTransfer(projectManagement.address);
  await ntt.mint(projectManagement.address, "1500000000000000000000000");
  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(ntt, "NTT");
  saveFrontendFiles(projectManagement, "ProjectManagement");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../../helpers";

async function main() {
  const [deployer] = await ethers.getSigners();

  const NTTAdd = readContractAddress("/NTT.json");
  const NTT = await ethers.getContractFactory("NTT");
  const ntt = await NTT.attach(NTTAdd);

  const ProjectManagement = await ethers.getContractFactory(
    "ProjectManagement"
  );
  const projectManagement = await ProjectManagement.deploy(ntt.address);
  await projectManagement.deployed();

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(projectManagement, "ProjectManagement");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

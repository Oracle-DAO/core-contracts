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
  const projectManagement = await ProjectManagement.deploy(ntt.address, {
    gasPrice: 110000000000,
  });
  await projectManagement.deployed();

  // const ProjectManagement = await ethers.getContractFactory("ProjectManagement");
  // const projectManagement = await ProjectManagement.attach(NTTAdd);

  console.log("Address of project Management:", projectManagement.address);
  await ntt.approveAddressForTransfer(projectManagement.address, {
    gasPrice: 110000000000,
  });

  await ntt.mint(projectManagement.address, "1500000000000000000000000", {
    gasPrice: 110000000000,
  });
  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(projectManagement, "ProjectManagement");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

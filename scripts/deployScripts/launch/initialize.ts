// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../../helpers";

async function main() {
  const [deployer] = await ethers.getSigners();

  const NTTAdd = readContractAddress("./NTT.json");
  const NTT = await ethers.getContractFactory("NTT");
  const ntt = await NTT.attach(NTTAdd);

  const ProjectManagementAdd = readContractAddress("/ProjectManagement.json");
  const ProjectManagement = await ethers.getContractFactory(
    "ProjectManagement"
  );
  const projectManagement = await ProjectManagement.attach(
    ProjectManagementAdd
  );

  await ntt.approveAddressForTransfer(projectManagement.address, {
    gasPrice: 110000000000,
  });
  console.log("projectManagement approved for txn");

  await ntt.mint(projectManagement.address, "1500000000000000000000000", {
    gasPrice: 110000000000,
  });
  console.log("projectManagement allotted tokens");

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

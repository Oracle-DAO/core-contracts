// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../../helpers";

async function main() {
  const [deployer] = await ethers.getSigners();

  const NTT = await ethers.getContractFactory("NTT");
  const ntt = await NTT.deploy({ gasPrice: 110000000000 });
  await ntt.deployed();

  console.log("Address of ntt:", ntt.address);
  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(ntt, "NTT");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

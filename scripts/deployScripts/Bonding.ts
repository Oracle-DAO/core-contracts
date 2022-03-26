// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress, saveFrontendFiles } from "../helpers";

async function main() {
  const [deployer, MockDao] = await ethers.getSigners();

  const treasuryAddress = readContractAddress("/Treasury.json");
  const mimAddress = readContractAddress("/MIM.json");
  const orfiAddress = readContractAddress("/ORFI.json");

  const Bond = await ethers.getContractFactory("Bond");
  const bond = await Bond.deploy(
    orfiAddress,
    mimAddress,
    treasuryAddress,
    MockDao.address
  );
  await bond.deployed();

  console.log("Token address of bond:", bond.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(bond, "Bond");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

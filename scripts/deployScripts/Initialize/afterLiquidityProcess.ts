// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const orfiAdd = readContractAddress("/ORFI.json");
const treasuryAdd = readContractAddress("/Treasury.json");
const lpManagerAdd = readContractAddress("/LpManager.json");
const lpAssetAdd = readContractAddress("/LpAsset.json");
const tavCalculatorAdd = readContractAddress("/TAVCalculator.json");

async function main() {
  const [deployer] = await ethers.getSigners();
  const ORFI = await ethers.getContractFactory("ORFI");
  const orfi = await ORFI.attach(orfiAdd);

  const LpManagerFact = await ethers.getContractFactory("LpManager");
  const LpManager = await LpManagerFact.attach(lpManagerAdd);

  const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
  const tavCalculator = await TAVCalculator.attach(tavCalculatorAdd);

  // await orfi.addLpContractAddress(constants.lpAddress);
  //
  // await LpManager.addLpAssetManager(lpAssetAdd);

  await tavCalculator.addAssetManager(lpManagerAdd);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

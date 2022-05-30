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

  const LpManagerFact = await ethers.getContractFactory("LpManager");
  const LpManager = await LpManagerFact.attach(lpManagerAdd);

  const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
  const tavCalculator = await TAVCalculator.attach(tavCalculatorAdd);

  await LpManager.blacklistAddress("0xFA6AffB61d4Cd5722Ab8Ce11009056EaE24d7E26");

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

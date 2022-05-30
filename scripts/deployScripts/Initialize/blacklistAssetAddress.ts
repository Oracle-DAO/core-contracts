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

  await LpManager.blacklistAddress("0x044059c5995a11ACD1A04033E5a28c93ddF91170");

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";

const tavCalculatorAdd = readContractAddress("/TAVCalculator.json");
const treasuryAdd = readContractAddress("/Treasury.json");
// const lpManagerAdd = readContractAddress("/lpManager.json");

async function main() {
  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.attach(treasuryAdd);

  const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
  const tavCalculator = await TAVCalculator.attach(tavCalculatorAdd);

  await tavCalculator.addAssetManager(treasury.address);
  console.log("step 9");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

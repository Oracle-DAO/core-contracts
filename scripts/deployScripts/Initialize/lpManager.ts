// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";

const lpAssetAdd = readContractAddress("/LpAsset.json");
const lpManagerAdd = readContractAddress("/LpManager.json");

async function main() {
  const LpManagerFact = await ethers.getContractFactory("LpManager");
  const LpManager = await LpManagerFact.attach(lpManagerAdd);

  await LpManager.addLpAssetManager(lpAssetAdd);
  console.log("step 3");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

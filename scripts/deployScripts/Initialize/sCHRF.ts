// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";

const sCHRFAdd = readContractAddress("/StakedCHRF.json");
const stakingAdd = readContractAddress("/Staking.json");

async function main() {
  const StakedCHRF = await ethers.getContractFactory("StakedCHRF");
  const sCHRF = await StakedCHRF.attach(sCHRFAdd);

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.attach(stakingAdd);

  await sCHRF.initialize(staking.address);
  console.log("step 7");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

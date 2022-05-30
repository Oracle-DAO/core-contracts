// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";

const sORFIAdd = readContractAddress("/StakedORFI.json");
const stakingAdd = readContractAddress("/Staking.json");

async function main() {
  const StakedORFI = await ethers.getContractFactory("StakedORFI");
  const sORFI = await StakedORFI.attach(sORFIAdd);

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.attach(stakingAdd);

  await sORFI.initialize(staking.address);
  console.log("step 7");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

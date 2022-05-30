// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const bondAdd = readContractAddress("/Bond.json");
const tavCalculatorAdd = readContractAddress("/TAVCalculator.json");
const stakingAdd = readContractAddress("/Staking.json");

async function main() {
  const MIMBond = await ethers.getContractFactory("Bond");
  const mimBond = await MIMBond.attach(bondAdd);

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.attach(stakingAdd);

  const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
  const tavCalculator = await TAVCalculator.attach(tavCalculatorAdd);

  await mimBond.initializeBondTerms(
    constants.mimBondBCV,
    constants.minBondPrice,
    constants.maxBondPayout,
    constants.minBondPayout,
    constants.bondFee,
    constants.bondRewardFee,
    constants.maxBondDebt,
    constants.bondVestingLength
  );

  console.log("Bond terms initialized completed");

  await mimBond.setTAVCalculator(tavCalculator.address);

  console.log("TAV calculator set completed");

  await mimBond.setStaking(staking.address);

  console.log("Staking address set completed");

  await mimBond.setFloorPriceValue(constants.floorPrice);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

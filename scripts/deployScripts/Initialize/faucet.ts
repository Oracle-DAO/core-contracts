// @ts-ignore
import { ethers } from "hardhat";
import { saveFrontendFiles } from "../helpers";
import {readContractAddress} from "../../helpers";

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  const [deployer] = await ethers.getSigners();

  const mimFaucetAdd = readContractAddress("/MIMFaucet.json");
  const chrFaucetfAdd = readContractAddress("/ChrfFaucet.json");

  const CHRF = await ethers.getContractFactory("MIM");
  const mimFaucet = await CHRF.attach(mimFaucetAdd);

  const chrfFaucet = await CHRF.attach(chrFaucetfAdd);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

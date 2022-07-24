// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const mimAdd = readContractAddress("/MIM.json");
const chrfAdd = readContractAddress("/CHRF.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  const CHRF = await ethers.getContractFactory("CHRF");
  const chrf = await CHRF.attach(chrfAdd);

  const MIM = await ethers.getContractFactory("MIM");
  const mim = await MIM.attach(mimAdd);

  // let txn = await chrf.setVault(deployer.address);
  // txn.wait();

  // await chrf.addLpContractAddress("0x5AB1b92D2991D3E6a51d2D2cF7c196296a855740");

  // console.log(await chrf.pair());
  // await chrf.addTaxExempt("0xE22994f609394EfFcD2c24520CaB1e968Da47D4a");

  await chrf.setMultiplier(7);
  // await mim.mint(deployer.address, constants.initialMint);

  // await mim.mint(deployer.address, "1000000000000000000000");
  // await chrf.mint(deployer.address, "1000000000000000000000000");
  // await chrf.setTax("1000");

  // await chrf.addLpContractAddress("0x0319000133d3ada02600f0875d2cf03d442c3367");

  console.log(await chrf.totalSupply());
  console.log("CHRF: " + chrfAdd);
  console.log("MIM Token: " + mimAdd);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

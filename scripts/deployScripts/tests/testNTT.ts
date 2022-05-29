// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const mimAdd = readContractAddress("/MIM.json");
const orfiAdd = readContractAddress("/ORFI.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  const ORFI = await ethers.getContractFactory("ORFI");
  const orfi = await ORFI.attach(orfiAdd);

  const MIM = await ethers.getContractFactory("MIM");
  const mim = await MIM.attach(mimAdd);

  // let txn = await orfi.setVault(deployer.address);
  // txn.wait();

  // await orfi.addLpContractAddress("0x5AB1b92D2991D3E6a51d2D2cF7c196296a855740");

  // console.log(await orfi.pair());
  // await orfi.addTaxExempt("0xE22994f609394EfFcD2c24520CaB1e968Da47D4a");

  await orfi.setMultiplier(7);
  // await mim.mint(deployer.address, constants.initialMint);

  // await mim.mint(deployer.address, "1000000000000000000000");
  // await orfi.mint(deployer.address, "1000000000000000000000000");
  // await orfi.setTax("1000");

  // await orfi.addLpContractAddress("0x0319000133d3ada02600f0875d2cf03d442c3367");

  console.log(await orfi.totalSupply());
  console.log("ORFI: " + orfiAdd);
  console.log("MIM Token: " + mimAdd);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

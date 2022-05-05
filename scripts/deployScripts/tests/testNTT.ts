// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";

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

  // await mim.mint(deployer.address, "1000000000000000000000");
  // await orfi.mint(deployer.address, "1000000000000000000000");
  // await orfi.setTax("1000");

  // await orfi.addLpContractAddress("0x0319000133d3ada02600f0875d2cf03d442c3367");

  console.log(await orfi.balanceOf("0x0319000133d3ada02600f0875d2cf03d442c3367"));
  console.log(await orfi.totalSupply());
  console.log("ORFI: " + orfiAdd);
  console.log("MIM Token: " + mimAdd);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

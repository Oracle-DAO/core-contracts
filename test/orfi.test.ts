import { ethers } from "hardhat";
import { constants } from "../scripts/constants";
import { expect } from "chai";
import { Contract } from "ethers";

describe("ORFI Test", function () {
  let orfi: Contract,
    mim: Contract,
    deployer: any;
  before(async () => {
    [deployer] = await ethers.getSigners();

    const MIM = await ethers.getContractFactory("MIM");
    mim = await MIM.deploy();
    await mim.deployed();

    const ORFI = await ethers.getContractFactory("ORFI");
    orfi = await ORFI.deploy();
    await orfi.deployed();

    // This will be the address of treasury
    await orfi.setVault(deployer.address);
  });

  it("Should check vault address", async function () {

    expect(await orfi.vault()).to.equal(deployer.address);

    await orfi.approve(deployer.address, "1000000000000000000");
    await orfi.mint(deployer.address, "1000000000000000000");

    expect(await orfi.balanceOf(deployer.address)).to.equal(
      "1000000000000000000"
    );
  });

  it("Should burn minted ORFI", async function () {

    await orfi.burnFrom(deployer.address, "1000000000000000000");

    expect(await orfi.balanceOf(deployer.address)).to.equal(
      "0"
    );
  });
});

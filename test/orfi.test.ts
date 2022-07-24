import { ethers } from "hardhat";
import { constants } from "../scripts/constants";
import { expect } from "chai";
import { Contract } from "ethers";

describe("CHRF Test", function () {
  let chrf: Contract,
    mim: Contract,
    deployer: any;
  before(async () => {
    [deployer] = await ethers.getSigners();

    const MIM = await ethers.getContractFactory("MIM");
    mim = await MIM.deploy();
    await mim.deployed();

    const CHRF = await ethers.getContractFactory("CHRF");
    chrf = await CHRF.deploy();
    await chrf.deployed();

    // This will be the address of treasury
    await chrf.setVault(deployer.address);
  });

  it("Should check vault address", async function () {

    expect(await chrf.vault()).to.equal(deployer.address);

    await chrf.approve(deployer.address, "1000000000000000000");
    await chrf.mint(deployer.address, "1000000000000000000");

    expect(await chrf.balanceOf(deployer.address)).to.equal(
      "1000000000000000000"
    );
  });

  it("Should burn minted CHRF", async function () {

    await chrf.burn("1000000000000000000");

    expect(await chrf.balanceOf(deployer.address)).to.equal(
      "0"
    );
  });
});

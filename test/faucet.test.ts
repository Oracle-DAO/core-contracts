import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";

describe("CHRF Faucet Test", function () {
  let chrf: Contract,
    mim: Contract,
    deployer: any,
    user1: any,
    user2: any,
    chrfFaucet: Contract;
  before(async () => {
    [deployer, user1, user2] = await ethers.getSigners();

    const MIM = await ethers.getContractFactory("MIM");
    mim = await MIM.deploy();
    await mim.deployed();

    const CHRF = await ethers.getContractFactory("CHRF");
    chrf = await CHRF.deploy();
    await chrf.deployed();

    const ChrfFaucet = await ethers.getContractFactory("ChrfFaucet");
    chrfFaucet = await ChrfFaucet.deploy(chrf.address);
    await chrfFaucet.deployed();

    await chrf.setVault(deployer.address);
  });

  it("CHRF faucet test", async function () {
    await chrf.mint(chrfFaucet.address, "500000000000000000000000");

    expect(await chrf.balanceOf(chrfFaucet.address)).to.be.equal(
      "500000000000000000000000"
    );

    await chrfFaucet.faucet(user1.address);

    expect(await chrf.balanceOf(chrfFaucet.address)).to.be.equal(
      "499900000000000000000000"
    );

    await chrfFaucet.faucet(user2.address);

    expect(await chrf.balanceOf(chrfFaucet.address)).to.be.equal(
      "499800000000000000000000"
    );

    expect(await chrf.balanceOf(user1.address)).to.be.equal(
      "100000000000000000000"
    );

    expect(await chrf.balanceOf(user2.address)).to.be.equal(
      "100000000000000000000"
    );
  });
});

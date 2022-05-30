import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";

describe("ORFI Faucet Test", function () {
  let orfi: Contract,
    mim: Contract,
    deployer: any,
    user1: any,
    user2: any,
    orfiFaucet: Contract;
  before(async () => {
    [deployer, user1, user2] = await ethers.getSigners();

    const MIM = await ethers.getContractFactory("MIM");
    mim = await MIM.deploy();
    await mim.deployed();

    const ORFI = await ethers.getContractFactory("ORFI");
    orfi = await ORFI.deploy();
    await orfi.deployed();

    const OrfiFaucet = await ethers.getContractFactory("OrfiFaucet");
    orfiFaucet = await OrfiFaucet.deploy(orfi.address);
    await orfiFaucet.deployed();

    await orfi.setVault(deployer.address);
  });

  it("ORFI faucet test", async function () {
    await orfi.mint(orfiFaucet.address, "500000000000000000000000");

    expect(await orfi.balanceOf(orfiFaucet.address)).to.be.equal(
      "500000000000000000000000"
    );

    await orfiFaucet.faucet(user1.address);

    expect(await orfi.balanceOf(orfiFaucet.address)).to.be.equal(
      "499900000000000000000000"
    );

    await orfiFaucet.faucet(user2.address);

    expect(await orfi.balanceOf(orfiFaucet.address)).to.be.equal(
      "499800000000000000000000"
    );

    expect(await orfi.balanceOf(user1.address)).to.be.equal(
      "100000000000000000000"
    );

    expect(await orfi.balanceOf(user2.address)).to.be.equal(
      "100000000000000000000"
    );
  });
});

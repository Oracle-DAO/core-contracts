import { ethers } from "hardhat";
import { constants } from "../scripts/constants";
import { expect } from "chai";
import { Contract } from "ethers";

describe("Staked ORFI Test-Cases", function () {
  it("mint sORFI via staking address", async function () {
    const [deployer] = await ethers.getSigners();

    const StakedORFI = await ethers.getContractFactory("StakedORFI");
    const stakedORFI = await StakedORFI.deploy();
    await stakedORFI.deployed();

    expect(await stakedORFI.initializer(), deployer.address);

    // Staking Address will go here
    await stakedORFI.initialize(deployer.address);

    await stakedORFI.mint(
      "0xa5BA5b45F73e4070492FBC801CBfF05F1A3FaDb8",
      "10000000000000000000"
    );

    expect(
      await stakedORFI.balanceOf("0xa5BA5b45F73e4070492FBC801CBfF05F1A3FaDb8")
    ).to.equal("10000000000000000000");

    expect(await stakedORFI.totalSupply()).to.equal("10000000000000000000");
  });
});

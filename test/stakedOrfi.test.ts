import { ethers } from "hardhat";
import { expect } from "chai";

describe("Staked CHRF Test-Cases", function () {
  it("mint sCHRF via staking address", async function () {
    const [deployer] = await ethers.getSigners();

    const StakedCHRF = await ethers.getContractFactory("StakedCHRF");
    const stakedCHRF = await StakedCHRF.deploy();
    await stakedCHRF.deployed();

    expect(await stakedCHRF.initializer(), deployer.address);

    // Staking Address will go here
    await stakedCHRF.initialize(deployer.address);

    await stakedCHRF.mint(
      "0xa5BA5b45F73e4070492FBC801CBfF05F1A3FaDb8",
      "10000000000000000000"
    );

    expect(
      await stakedCHRF.balanceOf("0xa5BA5b45F73e4070492FBC801CBfF05F1A3FaDb8")
    ).to.equal("10000000000000000000");

    expect(await stakedCHRF.totalSupply()).to.equal("10000000000000000000");
  });
});

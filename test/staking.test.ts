import { ethers } from "hardhat";
import { constants } from "../scripts/constants";
import { expect } from "chai";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Staking Test", function () {
  let deployer: SignerWithAddress;
  // let staker: SignerWithAddress;
  const stakingAmount = "100000000000000000000";
  let stakingAddress: any;
  let orfi: Contract;
  let sorfi: Contract;
  let taxManager: Contract;
  let DAO: any;
  let staking: Contract;
  let rewardDistributor: Contract;

  const delay = async (ms: number) => new Promise((res) => setTimeout(res, ms));

  beforeEach(async () => {
    [deployer, DAO] = await ethers.getSigners();
    stakingAddress = deployer.address;

    const MIM = await ethers.getContractFactory("MIM");
    const mim = await MIM.deploy();
    await mim.deployed();

    const ORFI = await ethers.getContractFactory("ORFI");
    orfi = await ORFI.deploy();
    await orfi.deployed();

    const TaxManager = await ethers.getContractFactory("TaxManager");
    taxManager = await TaxManager.deploy();

    // Only treasury can mint ORFI.
    await orfi.setVault(deployer.address);

    await orfi.setTax(500);

    await orfi.setTax(DAO.address);

    await orfi.mint(stakingAddress, stakingAmount);

    const sORFI = await ethers.getContractFactory("StakedORFI");
    sorfi = await sORFI.deploy();
    await sorfi.deployed();

    const Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(orfi.address, sorfi.address);
    await staking.deployed();

    const RewardDistributor = await ethers.getContractFactory(
      "RewardDistributor"
    );
    rewardDistributor = await RewardDistributor.deploy(
      staking.address,
      sorfi.address
    );
    await rewardDistributor.deployed();

    staking.setRewardDistributor(rewardDistributor.address);
    await sorfi.initialize(staking.address);
  });

  describe("Test user Stake and unstake", function () {
    it("Test user Stake and unstake", async function () {
      await orfi.approve(staking.address, stakingAmount);
      await staking.stake(stakingAddress, stakingAmount);

      expect(await sorfi.balanceOf(stakingAddress)).to.equal(stakingAmount);
      expect(await sorfi.balanceOf(staking.address)).to.equal(0);

      expect(await orfi.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await orfi.balanceOf(stakingAddress)).to.equal(0);

      await staking.unstake(stakingAddress, stakingAmount);
      expect(await sorfi.balanceOf(stakingAddress)).to.equal(0);
      expect(await sorfi.balanceOf(staking.address)).to.equal(0);

      expect(await orfi.balanceOf(staking.address)).to.equal(0);
      expect(await orfi.balanceOf(stakingAddress)).to.equal(stakingAmount);
    });
  });

  describe("Test user Stake with warmup and claim and then unstake", function () {
    it("Test user Stake with warmup and claim and then unstake", async function () {
      await staking.setWarmupLength(1);
      await orfi.approve(staking.address, stakingAmount);
      await staking.stake(stakingAddress, stakingAmount);

      expect(await sorfi.balanceOf(stakingAddress)).to.equal(0);
      expect(await sorfi.balanceOf(staking.address)).to.equal(0);

      expect(await orfi.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await orfi.balanceOf(stakingAddress)).to.equal(0);

      await delay(1000);
      await staking.claim(stakingAddress);

      expect(await sorfi.balanceOf(stakingAddress)).to.equal(stakingAmount);
      expect(await sorfi.balanceOf(staking.address)).to.equal(0);

      expect(await orfi.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await orfi.balanceOf(stakingAddress)).to.equal(0);

      await staking.unstake(stakingAddress, stakingAmount);
      expect(await sorfi.balanceOf(stakingAddress)).to.equal(0);
      expect(await sorfi.balanceOf(staking.address)).to.equal(0);

      expect(await orfi.balanceOf(staking.address)).to.equal(0);
      expect(await orfi.balanceOf(stakingAddress)).to.equal(stakingAmount);
    });
  });

  describe("Test user Stake with warmup and forfeit", function () {
    it("DTest user Stake with warmup and forfeit", async function () {
      await staking.setWarmupLength(1);
      await orfi.approve(staking.address, stakingAmount);
      await staking.stake(stakingAddress, stakingAmount);

      expect(await sorfi.balanceOf(stakingAddress)).to.equal(0);
      expect(await sorfi.balanceOf(staking.address)).to.equal(0);

      expect(await orfi.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await orfi.balanceOf(stakingAddress)).to.equal(0);

      await staking.forfeit();

      expect(await sorfi.balanceOf(stakingAddress)).to.equal(0);
      expect(await sorfi.balanceOf(staking.address)).to.equal(0);

      expect(await orfi.balanceOf(staking.address)).to.equal(0);
      expect(await orfi.balanceOf(stakingAddress)).to.equal(stakingAmount);
    });
  });
});

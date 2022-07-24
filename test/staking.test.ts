import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Staking Test", function () {
  let deployer: SignerWithAddress;
  // let staker: SignerWithAddress;
  const stakingAmount = "100000000000000000000";
  let stakingAddress: any;
  let chrf: Contract;
  let schrf: Contract;
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

    const CHRF = await ethers.getContractFactory("CHRF");
    chrf = await CHRF.deploy();
    await chrf.deployed();

    // Only treasury can mint CHRF.
    await chrf.setVault(deployer.address);

    await chrf.mint(stakingAddress, stakingAmount);

    const sCHRF = await ethers.getContractFactory("StakedCHRF");
    schrf = await sCHRF.deploy();
    await schrf.deployed();

    const Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(chrf.address, schrf.address);
    await staking.deployed();

    const RewardDistributor = await ethers.getContractFactory(
      "RewardDistributor"
    );
    rewardDistributor = await RewardDistributor.deploy(
      staking.address,
      schrf.address
    );
    await rewardDistributor.deployed();

    staking.setRewardDistributor(rewardDistributor.address);
    await schrf.initialize(staking.address);
  });

  describe("Test user Stake and unstake", function () {
    it("Test user Stake and unstake", async function () {
      await chrf.approve(staking.address, stakingAmount);
      await staking.stake(stakingAddress, stakingAmount);

      expect(await schrf.balanceOf(stakingAddress)).to.equal(stakingAmount);
      expect(await schrf.balanceOf(staking.address)).to.equal(0);

      expect(await chrf.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await chrf.balanceOf(stakingAddress)).to.equal(0);

      await staking.unstake(stakingAddress, stakingAmount);
      expect(await schrf.balanceOf(stakingAddress)).to.equal(0);
      expect(await schrf.balanceOf(staking.address)).to.equal(0);

      expect(await chrf.balanceOf(staking.address)).to.equal(0);
      expect(await chrf.balanceOf(stakingAddress)).to.equal(stakingAmount);
    });
  });

  describe("Test user Stake with warmup and claim and then unstake", function () {
    it("Test user Stake with warmup and claim and then unstake", async function () {
      await staking.setWarmupLength(1);
      await chrf.approve(staking.address, stakingAmount);
      await staking.stake(stakingAddress, stakingAmount);

      expect(await schrf.balanceOf(stakingAddress)).to.equal(0);
      expect(await schrf.balanceOf(staking.address)).to.equal(0);

      expect(await chrf.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await chrf.balanceOf(stakingAddress)).to.equal(0);

      await delay(1000);
      await staking.claim(stakingAddress);

      expect(await schrf.balanceOf(stakingAddress)).to.equal(stakingAmount);
      expect(await schrf.balanceOf(staking.address)).to.equal(0);

      expect(await chrf.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await chrf.balanceOf(stakingAddress)).to.equal(0);

      await staking.unstake(stakingAddress, stakingAmount);
      expect(await schrf.balanceOf(stakingAddress)).to.equal(0);
      expect(await schrf.balanceOf(staking.address)).to.equal(0);

      expect(await chrf.balanceOf(staking.address)).to.equal(0);
      expect(await chrf.balanceOf(stakingAddress)).to.equal(stakingAmount);
    });
  });

  describe("Test user Stake with warmup and forfeit", function () {
    it("DTest user Stake with warmup and forfeit", async function () {
      await staking.setWarmupLength(1);
      await chrf.approve(staking.address, stakingAmount);
      await staking.stake(stakingAddress, stakingAmount);

      expect(await schrf.balanceOf(stakingAddress)).to.equal(0);
      expect(await schrf.balanceOf(staking.address)).to.equal(0);

      expect(await chrf.balanceOf(staking.address)).to.equal(stakingAmount);
      expect(await chrf.balanceOf(stakingAddress)).to.equal(0);

      await staking.forfeit();

      expect(await schrf.balanceOf(stakingAddress)).to.equal(0);
      expect(await schrf.balanceOf(staking.address)).to.equal(0);

      expect(await chrf.balanceOf(staking.address)).to.equal(0);
      expect(await chrf.balanceOf(stakingAddress)).to.equal(stakingAmount);
    });
  });
});

import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ORFI, RewardDistributor, StakedORFI, Staking } from "../typechain";
import { constants } from "../scripts/constants";

describe("Deploy ORFI", function () {
  it("Should check vault address", async function () {
    const [deployer] = await ethers.getSigners();

    const ORFI = await ethers.getContractFactory("ORFI");
    const orfi = await ORFI.deploy();
    await orfi.deployed();

    // This will be the address of treasury
    await orfi.setVault(deployer.address);

    expect(await orfi.vault()).to.equal(deployer.address);

    await orfi.mint(deployer.address, "1000000000000000000");

    expect(await orfi.balanceOf(deployer.address)).to.equal(
      "1000000000000000000"
    );
  });
});

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

describe("Treasury Testing", function () {
  it("Deploy Treasury and Treasury Helper", async function () {
    const [deployer] = await ethers.getSigners();

    const MIM = await ethers.getContractFactory("MIM");
    const mim = await MIM.deploy();
    await mim.deployed();

    const ORFI = await ethers.getContractFactory("ORFI");
    const orfi = await ORFI.deploy();
    await orfi.deployed();

    const TreasuryHelper = await ethers.getContractFactory("TreasuryHelper");
    const treasuryHelper = await TreasuryHelper.deploy(
      orfi.address,
      mim.address,
      0
    );
    await treasuryHelper.deployed();

    // bond depository address will go here
    await treasuryHelper.queue("0", deployer.address);

    // bond depository address will go here
    await treasuryHelper.toggle(
      "0",
      deployer.address,
      "0x0000000000000000000000000000000000000000"
    );

    // reserve spender address will go here. They will burn ORFI
    await treasuryHelper.queue("1", deployer.address);

    // reserve spender address will go here
    await treasuryHelper.toggle(
      "1",
      deployer.address,
      "0x0000000000000000000000000000000000000000"
    );

    // reserve manager address will go here. They will allocate money
    await treasuryHelper.queue("3", deployer.address);

    // reserve manager address will go here. They will allocate money
    await treasuryHelper.toggle(
      "3",
      deployer.address,
      "0x0000000000000000000000000000000000000000"
    );

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy(
      orfi.address,
      treasuryHelper.address
    );
    await treasury.deployed();

    // Only treasury can mint ORFI.
    await orfi.setVault(treasury.address);

    expect(await treasury.treasuryHelper()).to.equal(
      await treasuryHelper.address
    );
    expect(await treasury.ORFI()).to.equal(orfi.address);

    // mint mim for msg.sender
    await mim.mint(deployer.address, "100000000000000000000");

    const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
    const tavCalculator = await TAVCalculator.deploy(
      orfi.address,
      treasury.address
    );
    await tavCalculator.deployed();

    // approve large number for treasury, so that it can move
    await mim.approve(treasury.address, constants.largeApproval);

    // approve treasury address for a user so that treasury can burn orfi for user
    await orfi.approve(treasury.address, constants.largeApproval);

    await treasury.setTAVCalculator(tavCalculator.address);

    expect(await mim.balanceOf(deployer.address)).to.equal(
      "100000000000000000000"
    );

    // Deposit 10 MIM and mint 5 ORFI
    await treasury.deposit(
      "10000000000000000000", // reserve token amount to deposit
      mim.address,
      "5000000000000000000" // amount of orfi to mint
    );

    expect(await treasury.totalReserves()).to.equal("10000000000000000000");

    // assuming the ORFI price to be 1$, burn 2.5$ of ORFI and retrive 2.5$
    // mim balance after this method for deployer is 92500000000000000000
    await treasury.withdraw("2500000000000000000", mim.address);

    expect(await treasury.totalReserves()).to.equal("7500000000000000000");

    // mim balance after this method for deployer is 97500000000000000000
    await treasury.manage(mim.address, "5000000000000000000");

    expect(await treasury.totalReserves()).to.equal("2500000000000000000");
    expect(await mim.balanceOf(deployer.address)).to.equal(
      "97500000000000000000"
    );
  });
});

describe("Bond Testing", function () {
  it("Bond Deposit and redeemed", async function () {
    const [deployer, DAO] = await ethers.getSigners();

    const MIM = await ethers.getContractFactory("MIM");
    const mim = await MIM.deploy();
    await mim.deployed();

    const ORFI = await ethers.getContractFactory("ORFI");
    const orfi = await ORFI.deploy();
    await orfi.deployed();

    const TreasuryHelper = await ethers.getContractFactory("TreasuryHelper");
    const treasuryHelper = await TreasuryHelper.deploy(
      orfi.address,
      mim.address,
      0
    );
    await treasuryHelper.deployed();

    // bond depository address will go here
    await treasuryHelper.queue("0", deployer.address);

    // bond depository address will go here
    await treasuryHelper.toggle("0", deployer.address, constants.zeroAddress);

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy(
      orfi.address,
      treasuryHelper.address
    );
    await treasury.deployed();

    // Only treasury can mint ORFI.
    await orfi.setVault(treasury.address);

    // mint mim for msg.sender
    await mim.mint(deployer.address, "10000000000000000000000000");

    const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
    const tavCalculator = await TAVCalculator.deploy(
      orfi.address,
      treasury.address
    );
    await tavCalculator.deployed();

    // approve large number for treasury, so that it can move
    await mim.approve(treasury.address, constants.largeApproval);

    // approve treasury address for a user so that treasury can burn orfi for user
    await orfi.approve(treasury.address, constants.largeApproval);

    await treasury.setTAVCalculator(tavCalculator.address);

    // Deposit 1,000,000 MIM and mint 1,000,000 ORFI
    await treasury.deposit(
      "1000000000000000000000000", // reserve token amount to deposit
      mim.address,
      "1000000000000000000000000" // amount of orfi to mint
    );

    const Bond = await ethers.getContractFactory("Bond");
    const bond = await Bond.deploy(
      orfi.address,
      mim.address,
      treasury.address,
      DAO.address
    );

    await bond.deployed();

    await bond.initializeBondTerms(
      constants.mimBondBCV,
      constants.minBondPrice,
      constants.maxBondPayout,
      constants.minBondPayout,
      constants.bondFee,
      constants.maxBondDebt,
      constants.bondVestingLength
    );

    await bond.setTAVCalculator(tavCalculator.address);
    // approve large number for treasury, so that it can move
    await mim.approve(bond.address, constants.largeApproval);

    // bond depository address will go here
    await treasuryHelper.queue("0", bond.address);

    // bond depository address will go here
    await treasuryHelper.toggle("0", bond.address, constants.zeroAddress);

    let orfiBalance, orfiBalance1;
    await bond.deposit("100000000000000000000000", "600000", deployer.address);

    orfiBalance1 = 0;
    orfiBalance = await orfi.balanceOf(DAO.address);
    expect(orfiBalance).to.gt(orfiBalance1);
    orfiBalance1 = orfiBalance;
    await bond.deposit("100000000000000000000000", "600000", deployer.address);

    orfiBalance = await orfi.balanceOf(DAO.address);
    expect(orfiBalance).to.gt(orfiBalance1);
    orfiBalance1 = orfiBalance;

    await bond.deposit("100000000000000000000000", "600000", deployer.address);

    orfiBalance = await orfi.balanceOf(DAO.address);
    expect(orfiBalance).to.gt(orfiBalance1);
  });
});

describe("Staking Test", function () {
  let deployer: SignerWithAddress;
  // let staker: SignerWithAddress;
  const stakingAmount = "100000000000000000000";
  let stakingAddress: any;
  let orfi: ORFI;
  let sorfi: StakedORFI;
  let staking: Staking;
  let rewardDistributor: RewardDistributor;

  const delay = async (ms: number) => new Promise((res) => setTimeout(res, ms));

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();
    stakingAddress = deployer.address;

    const MIM = await ethers.getContractFactory("MIM");
    const mim = await MIM.deploy();
    await mim.deployed();

    const ORFI = await ethers.getContractFactory("ORFI");
    orfi = await ORFI.deploy();
    await orfi.deployed();

    await orfi.setVault(deployer.address);
    await orfi.mint(stakingAddress, stakingAmount);

    const sORFI = await ethers.getContractFactory("StakedORFI");
    sorfi = await sORFI.deploy();
    await sorfi.deployed();

    const Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(orfi.address, sorfi.address);
    await staking.deployed();

    const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
    rewardDistributor = await RewardDistributor.deploy(staking.address, sorfi.address);
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

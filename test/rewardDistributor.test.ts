import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
describe("Reward Distributor", async () => {
  let mockOrfi: Contract,
    mockStakedOrfi: Contract,
    mockStaking: any,
    rewardDistributor: Contract,
    deployer: any,
    user1: any,
    user2: any,
    mim: Contract,
    treasury: Contract,
    treasuryHelper: Contract,
    rewardAmount: string;

  const delay = async (ms: number) => new Promise((res) => setTimeout(res, ms));

  before(async () => {
    [deployer, user1, user2] = await ethers.getSigners();

    const mockOrfiFact = await ethers.getContractFactory("MockORFI");
    mockOrfi = await mockOrfiFact.deploy();

    await mockOrfi.deployed();

    const mockStakedORFIFact = await ethers.getContractFactory(
      "MockStakedORFI"
    );
    mockStakedOrfi = await mockStakedORFIFact.deploy();

    const mockMimFact = await ethers.getContractFactory(
      "MIM"
    );
    mim = await mockMimFact.deploy();
    await mim.deployed();

    await mockStakedOrfi.deployed();

    const mockStakingFact = await ethers.getContractFactory("MockStaking");
    mockStaking = await mockStakingFact.deploy(
      mockOrfi.address,
      mockStakedOrfi.address
    );

    await mockStaking.deployed();

    const rewardDistributorFact = await ethers.getContractFactory(
      "RewardDistributor"
    );
    rewardDistributor = await rewardDistributorFact.deploy(
      mockStaking.address,
      mockStakedOrfi.address
    );

    await rewardDistributor.deployed();

    await mockStakedOrfi.mint(deployer.address, constants.initialMint);

    const treasuryHelperFact = await ethers.getContractFactory("TreasuryHelper");
    treasuryHelper = await treasuryHelperFact.deploy(mockOrfi.address, mim.address, 0);
    await treasuryHelper.deployed();

    const treasuryFact = await ethers.getContractFactory("Treasury");
    treasury = await treasuryFact.deploy(mockOrfi.address, treasuryHelper.address);
    await treasury.deployed();

    await treasuryHelper.queue("3", rewardDistributor.address);

    // reserve spender address will go here
    await treasuryHelper.toggle("3", rewardDistributor.address, constants.zeroAddress);

    await mim.approve(treasury.address, constants.largeApproval);
    await mim.mint(treasury.address, constants.largeApproval);
  });

  it("Check staking and stakedOrfi Address", async function () {
    expect(await rewardDistributor.stakingContract()).to.equal(
      mockStaking.address
    );

    expect(await rewardDistributor.stakedOrfiAddress()).to.equal(
      mockStakedOrfi.address
    );
  });

  it("Check staking", async function () {
    await mockStaking.setRewardDistributor(rewardDistributor.address);
    expect(await mockStaking.getRewardDistributorAddress()).to.equal(
      rewardDistributor.address
    );

    await mockOrfi.mint(deployer.address, constants.largeApproval);
    await mockOrfi.approve(mockStaking.address, constants.largeApproval);

    await mockStaking.stake(deployer.address, "400000000000000000000000");

    await mockStaking.stake(deployer.address, "800000000000000000000000");

    await rewardDistributor.completeRewardCycle(constants.initialMint);
  });

  it("Check redeem for a cycle", async function () {
    await mockStaking.setRewardDistributor(rewardDistributor.address);
    await rewardDistributor.setTreasuryAddress(treasury.address);
    await rewardDistributor.setStableCoinAddress(mim.address);
    expect(await mockStaking.getRewardDistributorAddress()).to.equal(
      rewardDistributor.address
    );

    await mockOrfi.mint(user1.address, constants.largeApproval);
    await mockOrfi.connect(user1).approve(mockStaking.address, constants.largeApproval);

    await mockStaking.connect(user1).stake(user1.address, "400000000000000000000000");
    await mockStaking.connect(user1).stake(user1.address, "800000000000000000000000");

    delay(10000);

    await rewardDistributor.completeRewardCycle(constants.initialMint);
    //
    const rewardsForCycle = await rewardDistributor.connect(user1).rewardsForACycle(user1.address, 2);
    //
    expect(parseFloat(rewardsForCycle)).to.gt(0);

  });

  it("Check complete reward cycle", async function () {
    rewardAmount = constants.initialMint;
    expect(await rewardDistributor.currentRewardCycle()).to.equal(3);

    await rewardDistributor.completeRewardCycle(rewardAmount);
    expect(await rewardDistributor.currentRewardCycle()).to.equal(4);
    expect(await rewardDistributor.getTotalRewardsForCycle(1)).to.equal(
      rewardAmount
    );
  });
});

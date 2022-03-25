import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
describe("Reward Distributor", async () => {
  let mockOrcl: Contract,
    mockStakedOrcl: Contract,
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

    const mockOrclFact = await ethers.getContractFactory("MockORCL");
    mockOrcl = await mockOrclFact.deploy();

    await mockOrcl.deployed();

    const mockStakedORCLFact = await ethers.getContractFactory(
      "MockStakedORCL"
    );
    mockStakedOrcl = await mockStakedORCLFact.deploy();

    const mockMimFact = await ethers.getContractFactory(
      "MIM"
    );
    mim = await mockMimFact.deploy();
    await mim.deployed();

    await mockStakedOrcl.deployed();

    const mockStakingFact = await ethers.getContractFactory("MockStaking");
    mockStaking = await mockStakingFact.deploy(
      mockOrcl.address,
      mockStakedOrcl.address
    );

    await mockStaking.deployed();

    const rewardDistributorFact = await ethers.getContractFactory(
      "RewardDistributor"
    );
    rewardDistributor = await rewardDistributorFact.deploy(
      mockStaking.address,
      mockStakedOrcl.address
    );

    await rewardDistributor.deployed();

    await mockStakedOrcl.mint(deployer.address, constants.initialMint);

    const treasuryHelperFact = await ethers.getContractFactory("TreasuryHelper");
    treasuryHelper = await treasuryHelperFact.deploy(mockOrcl.address, mim.address, 0);
    await treasuryHelper.deployed();

    const treasuryFact = await ethers.getContractFactory("Treasury");
    treasury = await treasuryFact.deploy(mockOrcl.address, treasuryHelper.address);
    await treasury.deployed();

    await treasuryHelper.queue("3", rewardDistributor.address);

    // reserve spender address will go here
    await treasuryHelper.toggle("3", rewardDistributor.address, constants.zeroAddress);

    console.log(await treasuryHelper.isReserveManager(rewardDistributor.address));

    await mim.approve(treasury.address, constants.largeApproval);
    await mim.mint(treasury.address, constants.largeApproval);
  });

  it("Check staking and stakedOrcl Address", async function () {
    expect(await rewardDistributor.stakingContract()).to.equal(
      mockStaking.address
    );

    expect(await rewardDistributor.stakedOrclAddress()).to.equal(
      mockStakedOrcl.address
    );
  });

  it("Check staking", async function () {
    await mockStaking.setRewardDistributor(rewardDistributor.address);
    expect(await mockStaking.getRewardDistributorAddress()).to.equal(
      rewardDistributor.address
    );

    await mockOrcl.mint(deployer.address, constants.largeApproval);
    await mockOrcl.approve(mockStaking.address, constants.largeApproval);

    await mockStaking.stake(deployer.address, "400000000000000000000000");

    await mockStaking.stake(deployer.address, "800000000000000000000000");

    await rewardDistributor.completeRewardCycle(constants.initialMint);
  });

  it("Check redeem for a cycle", async function () {
    console.log(rewardDistributor.address);

    await mockStaking.setRewardDistributor(rewardDistributor.address);
    await rewardDistributor.setTreasuryAddress(treasury.address);
    await rewardDistributor.setStableCoinAddress(mim.address);
    expect(await mockStaking.getRewardDistributorAddress()).to.equal(
      rewardDistributor.address
    );

    await mockOrcl.mint(user1.address, constants.largeApproval);
    await mockOrcl.connect(user1).approve(mockStaking.address, constants.largeApproval);

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

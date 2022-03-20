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

  it("Check complete reward cycle", async function () {
    rewardAmount = constants.initialMint;
    expect(await rewardDistributor.currentRewardCycle()).to.equal(1);

    await rewardDistributor.completeRewardCycle(rewardAmount);
    expect(await rewardDistributor.currentRewardCycle()).to.equal(2);
    expect(await rewardDistributor.getTotalRewardsForCycle(1)).to.equal(
      rewardAmount
    );
  });
});

import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
describe("Reward Distributor", async () => {
  let mockChrf: Contract,
    mockStakedChrf: Contract,
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

    const mockChrfFact = await ethers.getContractFactory("MockCHRF");
    mockChrf = await mockChrfFact.deploy();

    await mockChrf.deployed();

    const mockStakedCHRFFact = await ethers.getContractFactory(
      "MockStakedCHRF"
    );
    mockStakedChrf = await mockStakedCHRFFact.deploy();

    const mockMimFact = await ethers.getContractFactory("MIM");
    mim = await mockMimFact.deploy();
    await mim.deployed();

    await mockStakedChrf.deployed();

    const mockStakingFact = await ethers.getContractFactory("MockStaking");
    mockStaking = await mockStakingFact.deploy(
      mockChrf.address,
      mockStakedChrf.address
    );

    await mockStaking.deployed();

    const rewardDistributorFact = await ethers.getContractFactory(
      "RewardDistributor"
    );
    rewardDistributor = await rewardDistributorFact.deploy(
      mockStaking.address,
      mockStakedChrf.address
    );

    await rewardDistributor.deployed();

    await mockStakedChrf.mint(deployer.address, constants.initialMint);

    const treasuryHelperFact = await ethers.getContractFactory(
      "TreasuryHelper"
    );
    treasuryHelper = await treasuryHelperFact.deploy(
      mockChrf.address,
      mim.address,
      0
    );
    await treasuryHelper.deployed();

    const treasuryFact = await ethers.getContractFactory("Treasury");
    treasury = await treasuryFact.deploy(
      mockChrf.address,
      treasuryHelper.address
    );
    await treasury.deployed();

    await treasuryHelper.queue("3", rewardDistributor.address);

    // reserve spender address will go here
    await treasuryHelper.toggle(
      "3",
      rewardDistributor.address,
      constants.zeroAddress
    );

    await mim.approve(treasury.address, constants.largeApproval);
    await mim.mint(treasury.address, constants.largeApproval);
  });

  it("Check staking and stakedChrf Address", async function () {
    expect(await rewardDistributor.stakingContract()).to.equal(
      mockStaking.address
    );

    expect(await rewardDistributor.stakedChrfAddress()).to.equal(
      mockStakedChrf.address
    );
  });

  it("Check staking", async function () {
    await mockStaking.setRewardDistributor(rewardDistributor.address);
    expect(await mockStaking.getRewardDistributorAddress()).to.equal(
      rewardDistributor.address
    );

    await mockChrf.mint(deployer.address, constants.largeApproval);
    await mockChrf.approve(mockStaking.address, constants.largeApproval);

    await mockStaking.stake(deployer.address, "400000000000000000000000");

    await mockStaking.stake(deployer.address, "800000000000000000000000");

    console.log(await rewardDistributor.getTotalStakedChrfOfUserForACycle(deployer.address, 1));

    await mockStaking.unstake(deployer.address, "500000000000000000000000");

    console.log(await rewardDistributor.getTotalStakedChrfOfUserForACycle(deployer.address, 1));
    // await rewardDistributor.completeRewardCycle(constants.initialMint);
  });
  //
  // it("Check redeem for a cycle", async function () {
  //   await mockStaking.setRewardDistributor(rewardDistributor.address);
  //   await rewardDistributor.setTreasuryAddress(treasury.address);
  //   await rewardDistributor.setStableCoinAddress(mim.address);
  //   expect(await mockStaking.getRewardDistributorAddress()).to.equal(
  //     rewardDistributor.address
  //   );
  //
  //   await mockChrf.mint(user1.address, constants.largeApproval);
  //   await mockChrf
  //     .connect(user1)
  //     .approve(mockStaking.address, constants.largeApproval);
  //
  //   await mockStaking
  //     .connect(user1)
  //     .stake(user1.address, "400000000000000000000000");
  //   await mockStaking
  //     .connect(user1)
  //     .stake(user1.address, "800000000000000000000000");
  //
  //   delay(10000);
  //
  //   await rewardDistributor.completeRewardCycle(constants.initialMint);
  //   await mockStaking
  //     .connect(user1)
  //     .stake(user1.address, "800000000000000000000000");
  //
  //   const rewardsForCycle = await rewardDistributor
  //     .connect(user1)
  //     .rewardsForACycle(user1.address, 2);
  //
  //   // console.log("rewards for cycle", rewardsForCycle);
  //   expect(parseFloat(rewardsForCycle)).to.gt(0);
  // });
  //
  // it("Check complete reward cycle", async function () {
  //   rewardAmount = constants.initialMint;
  //   expect(await rewardDistributor.currentRewardCycle()).to.equal(3);
  //
  //   await rewardDistributor.completeRewardCycle(rewardAmount);
  //   expect(await rewardDistributor.currentRewardCycle()).to.equal(4);
  //   expect(await rewardDistributor.getTotalRewardsForCycle(1)).to.equal(
  //     rewardAmount
  //   );
  // });
  //
  // it("Check Reward with gaps in cycle", async function () {
  //   rewardAmount = constants.initialMint;
  //   expect(await rewardDistributor.currentRewardCycle()).to.equal(4);
  //   await mockStaking.unstake(deployer.address, "400000000000000000000000");
  //   expect(
  //     await rewardDistributor.getTotalStakedChrfOfUserForACycle(deployer.address, 2)
  //   ).to.gt(0);
  //   await rewardDistributor.completeRewardCycle(rewardAmount);
  //   // console.log(await rewardDistributor.rewardsForACycle(deployer.address, 1));
  //   // console.log(await rewardDistributor.rewardsForACycle(deployer.address, 2));
  //   // console.log(await rewardDistributor.rewardsForACycle(deployer.address, 3));
  //   // console.log(await rewardDistributor.rewardsForACycle(deployer.address, 4));
  //   //
  //   // console.log(await rewardDistributor.getTotalStakedChrfOfUserForACycle(deployer.address, 1));
  //   // console.log(await rewardDistributor.getTotalStakedChrfOfUserForACycle(deployer.address, 2));
  //   // console.log(await rewardDistributor.getTotalStakedChrfOfUserForACycle(deployer.address, 3));
  //   // console.log(await rewardDistributor.getTotalStakedChrfOfUserForACycle(deployer.address, 4));
  //
  //   // console.log(await rewardDistributor.getTotalStakedChrfForACycle(4));
  //
  // });
});

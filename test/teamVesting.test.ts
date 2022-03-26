import { expect } from "chai";
import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { constants } from "../scripts/constants";
import { Contract } from "ethers";
describe("NTT and Project Management Contract", async () => {
  let nttContract: Contract,
    projectManagement: Contract,
    mockOrfi: Contract,
    deployer: any,
    user1: any,
    user2: any,
    user3: any,
    rewardAmount: string;

  const delay = async (ms: number) => new Promise((res) => setTimeout(res, ms));

  before(async () => {
    [deployer, user1, user2, user3] = await ethers.getSigners();

    const mockOrfiFact = await ethers.getContractFactory("MockORFI");
    mockOrfi = await mockOrfiFact.deploy();

    await mockOrfi.deployed();

    const nttFact = await ethers.getContractFactory("NTT");
    nttContract = await nttFact.deploy();

    await nttContract.deployed();

    await nttContract.setOrfiAddress(mockOrfi.address);

    await mockOrfi.mint(nttContract.address, "5000000000000000000000000");

    const ProjectManagementFact = await ethers.getContractFactory(
      "ProjectManagement"
    );
    projectManagement = await ProjectManagementFact.deploy(nttContract.address);

    await projectManagement.deployed();

    await nttContract.mint(
      projectManagement.address,
      "1500000000000000000000000"
    );

    await nttContract.approveAddressForTransfer(projectManagement.address);
  });

  it("Check orfi and nOrfi Balance", async function () {
    expect(await mockOrfi.balanceOf(nttContract.address)).to.equal(
      "5000000000000000000000000"
    );

    expect(await nttContract.balanceOf(projectManagement.address)).to.equal(
      "1500000000000000000000000"
    );

    expect(await projectManagement.totalRemainingTeamToken()).to.equal(
      "1000000000000000000000000"
    );

    expect(await projectManagement.totalRemainingMarketingToken()).to.equal(
      "500000000000000000000000"
    );
  });

  it("Check set Member Info", async function () {
    await projectManagement.setMemberInfo(
      user1.address,
      "150000000000000000000000",
      60,
      true
    );

    expect(await projectManagement.checkPayout(user1.address)).to.equal(
      "150000000000000000000000"
    );

    expect(await projectManagement.totalRemainingTeamToken()).to.equal(
      "850000000000000000000000"
    );

    await projectManagement.setMemberInfo(
      user2.address,
      "50000000000000000000000",
      60,
      true
    );
    expect(await projectManagement.totalRemainingTeamToken()).to.equal(
      "800000000000000000000000"
    );
  });

  it("Check redeemed and blacklist", async function () {
    await projectManagement.connect(user1).redeem(user1.address);
    expect(await projectManagement.totalRemainingTeamToken()).to.equal(
      "800000000000000000000000"
    );
    await projectManagement.blacklistAndRedeem(user1.address);

    await expect(projectManagement.connect(user1).redeem(user1.address)).to.revertedWith("Not a team member")
  });

  it("Check marketing redeem", async function () {

    await projectManagement.setMarketingManager(user2.address);
    expect(await projectManagement.marketingManager(user2.address)).to.equal(true)

    await expect(projectManagement.redeemTokenForMarketing(user3.address, "50000000000000000000000"))
      .to.revertedWith("Not a marketing Manager");

    await projectManagement.connect(user2).redeemTokenForMarketing(user3.address, "50000000000000000000000");
    expect(await projectManagement.totalRemainingMarketingToken()).to.equal("450000000000000000000000")
  });

  it("Redeem ORFI for nORFI", async function () {
    await nttContract.toggleRedeemFlag();

    const user1NttBalance = await nttContract.balanceOf(user1.address);
    const user2NttBalance = await nttContract.balanceOf(user2.address);

    await nttContract.connect(user1).redeemORFI(user1NttBalance);
    await nttContract.connect(user2).redeemORFI(user2NttBalance);

    expect(await mockOrfi.balanceOf(user1.address)).to.equal(user1NttBalance);
    expect(await mockOrfi.balanceOf(user2.address)).to.equal(user2NttBalance);
  });

  it("Check Excess mint of NTT", async function () {
    const totalSupply = await nttContract.totalNTTMinted();
    expect(totalSupply).to.equal("1500000000000000000000000");

    await nttContract.mint(user3.address, "3500000000000000000000000");
    expect(await nttContract.totalNTTMinted()).to.equal("5000000000000000000000000");

    await expect(nttContract.mint(user3.address, "1000000000000000000")).to.revertedWith("Total supply will expected NTT supply");
  });

});

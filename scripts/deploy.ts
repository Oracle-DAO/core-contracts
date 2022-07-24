// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { constants } from "./constants";

async function main() {
  const [deployer, DAO] = await ethers.getSigners();

  const chrf = await ethers.getContractFactory("CHRF");
  const chrfContract = await chrf.deploy();

  await chrfContract.deployed();

  const StakedCHRF = await ethers.getContractFactory("StakedCHRF");
  const sCHRFContract = await StakedCHRF.deploy();
  await sCHRFContract.deployed();

  // Only Needed for mock.
  const MIM = await ethers.getContractFactory("MIM");
  const mim = await MIM.deploy();
  await mim.deployed();

  const Staking = await ethers.getContractFactory("Staking");
  const stakingContract = await Staking.deploy(
    chrfContract.address,
    sCHRFContract.address
  );
  await stakingContract.deployed();

  const TreasuryHelper = await ethers.getContractFactory("TreasuryHelper");
  const treasuryHelper = await TreasuryHelper.deploy(
    chrfContract.address,
    mim.address,
    constants.blockNeededToWait
  );
  await treasuryHelper.deployed();

  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy(
    chrfContract.address,
    treasuryHelper.address
  );
  await treasury.deployed();

  const TAVCalculator = await ethers.getContractFactory("TAVCalculator");
  const tavCalculator = await TAVCalculator.deploy(
    chrfContract.address,
    treasury.address
  );
  await tavCalculator.deployed();

  const Bond = await ethers.getContractFactory("Bond");
  const bond = await Bond.deploy(
    chrfContract.address,
    mim.address,
    treasury.address,
    DAO.address,
    constants.zeroAddress
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

  await chrfContract.setVault(treasury.address);

  await sCHRFContract.initialize(stakingContract.address);

  // bond depository address will go here
  await treasuryHelper.queue("0", bond.address);

  // bond depository address will go here
  await treasuryHelper.toggle("0", bond.address, constants.zeroAddress);

  // reserve spender address will go here. They will burn CHRF
  await treasuryHelper.queue("1", deployer.address);

  // reserve spender address will go here
  await treasuryHelper.toggle("1", deployer.address, constants.zeroAddress);

  // reserve manager address will go here. They will allocate money
  await treasuryHelper.queue("3", deployer.address);

  // reserve manager address will go here. They will allocate money
  await treasuryHelper.toggle("3", deployer.address, constants.zeroAddress);

  // approve large number for treasury, so that it can move
  await mim.approve(treasury.address, constants.largeApproval);

  // approve large number for treasury, so that it can transfer token as spender
  await mim.approve(bond.address, constants.largeApproval);

  // approve treasury address for a user so that treasury can burn chrf for user
  await chrfContract.approve(treasury.address, constants.largeApproval);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

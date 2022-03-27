// @ts-ignore
import { ethers } from "hardhat";
import { readContractAddress } from "../../helpers";
import { constants } from "../../constants";

const nttAdd = readContractAddress("/NTT.json");
const projectManagamentAdd = readContractAddress("/ProjectManagement.json");

async function main() {
  const [deployer, deployer1] = await ethers.getSigners();

  const NTT = await ethers.getContractFactory("NTT");
  const ntt = await NTT.attach(nttAdd);

  const ORFI = await ethers.getContractFactory("ORFI");
  const orfi = await ORFI.attach("0xea664D289C7EFfCFB6Cb5723B436481f65B4E54B");

  const ProjectManagement = await ethers.getContractFactory(
    "ProjectManagement"
  );
  const projectManagement = await ProjectManagement.attach(
    projectManagamentAdd
  );

  console.log(
    await orfi.balanceOf("0xD107F7087Aa5489Ca71521Cb64628c7bE61ECbE1")
  );

  // await ntt.setOrfiAddress("0xea664D289C7EFfCFB6Cb5723B436481f65B4E54B");

  // await ntt.toggleRedeemFlag();

  // TEAM Redeem
  await projectManagement.setMemberInfo(deployer1.address, "150000000000000000000000", 60, true);
  console.log(await ntt.balanceOf(deployer1.address));
  await projectManagement.connect(deployer1).redeem(deployer1.address);
  console.log(await ntt.balanceOf(deployer1.address));

  // Marketing manager
  await projectManagement.setMarketingManager(deployer1.address);
  await projectManagement.connect(deployer1).redeemTokenForMarketing(deployer.address, "150000000000000000000000");
  console.log(await ntt.balanceOf(deployer.address));

  // Blacklist and redeem
  await projectManagement.setMemberInfo(deployer1.address, "15000000000000000000000", 2000, true);
  console.log(await ntt.balanceOf(deployer1.address));
  await projectManagement.blacklistAndRedeem(deployer1.address);
  console.log(await ntt.balanceOf(deployer1.address));
  console.log(await projectManagement.checkPayout(deployer1.address));

  // Redeem ORCL
  const supply1 = await ntt.totalSupply();

  await ntt.connect(deployer1).redeemORFI("150000000000000000000");

  const supply2 = await ntt.totalSupply();
  console.log("supply before", supply1);
  console.log("supply after", supply2);
  console.log("contracts are attached to their ABIs");
  console.log("NTT: " + nttAdd);
  console.log("ProjectManagement: " + projectManagamentAdd);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

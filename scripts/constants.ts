export class constants {
  public static floorPrice = "1300000000";
  public static initialIndex = "7675210820";
  public static firstEpochBlock = "8961000"; // Should be the deployement time in uint32(block.timestamp)
  public static firstEpochNumber = "1"; // for every rebase done, this increase by 1. This can be used as a vesting strategy
  public static epochLengthInBlocks = "3600"; // time for rebase in seconds, 8 hrs i.e 8*3600
  public static initialRewardRate = "300"; // try to reduce and check it's effect
  public static zeroAddress = "0x0000000000000000000000000000000000000000";
  public static largeApproval = "100000000000000000000000000000000";
  public static initialMint = "10000000000000000000000000";
  public static mimBondBCV = "100";
  public static bondVestingLength = "1200"; // 3 days times in second (3*24*3600)
  public static minBondPrice = "500000";
  public static maxBondPayout = "10000"; // max payout 10 % of total supply
  public static minBondPayout = "10000000000000000"; // 0.01 ORFI
  public static bondFee = "5000"; // DAO fees 5 %
  public static bondRewardFee = "10000"; // bonding reward fee %
  public static maxBondDebt = "1000000000000000000000000";
  public static adjustmentIncrement = "3";
  public static blockNeededToWait = "0";
  public static lpAddress = "0x9351385398108d17A67070805f2c8974dEa2ddE0";
  public static principalToken = "0x6A7368aF06F063CBf4E7A12d99f0f7b819e1f298";
}

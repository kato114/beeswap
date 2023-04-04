const { ethers, upgrades } = require("hardhat");

async function main() {
  const gas = await ethers.provider.getGasPrice();
  const beeswapTreasury = await ethers.getContractAt(
    "BeeswapTreasury",
    "0xc1a6d135c86e9f4609d541154082298d3c865c77"
  );
  const beeswapRouter = await ethers.getContractAt(
    "BeeswapRouter",
    "0x11e171c3f4b117F00ABb285Dd14013215Fa4e6F4"
  );
  //   console.log(
  //     "Treasury Initialzied:",
  //     await beeswapTreasury.deposit("100000000000000000000")
  //   );
  console.log(
    "Treasury Initialzied:",
    await beeswapRouter.swapInToken(
      "0xc4Bd25aE6Be05AbcCb667427Dca4A2Cc0D2B2802",
      "100000000000000000000",
      5,
      "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
      "0x2080F3b056978e76913efdF7F15EaB5130B7647B",
      "10000000000000"
    )
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

const { ethers, upgrades } = require("hardhat");

async function main() {
  const gas = await ethers.provider.getGasPrice();
  const BeeswapTreasury = await ethers.getContractFactory("BeeswapTreasury");
  console.log("Deploying BeeswapTreasury...");
  const beeswapTreasury = await upgrades.deployProxy(
    BeeswapTreasury,
    ["0x6A9b66b9C251bA43Df2608f985Ea9b7619C0bA49"],
    {
      gasPrice: gas,
      initializer: "initialize",
    }
  );
  await beeswapTreasury.deployed();
  console.log("BeeswapTreasury Contract deployed to:", beeswapTreasury.address);

  const BeeswapRouter = await ethers.getContractFactory("BeeswapRouter");
  console.log("Deploying BeeswapRouter...");
  const beeswapRouter = await upgrades.deployProxy(
    BeeswapRouter,
    [
      "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
      "0x6A9b66b9C251bA43Df2608f985Ea9b7619C0bA49",
      "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      beeswapTreasury.address,
    ],
    {
      gasPrice: gas,
      initializer: "initialize",
    }
  );
  await beeswapRouter.deployed();
  console.log("BeeswapRouter Contract deployed to:", beeswapRouter.address);

  await beeswapTreasury.setRouterAddress(beeswapRouter.address);
  console.log("Treasury Initialzied:");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

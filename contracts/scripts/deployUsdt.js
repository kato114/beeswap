const { ethers, upgrades } = require("hardhat");

async function main() {
  const Usdt = await ethers.getContractFactory("BEP20USDT");
  const usdt = await Usdt.deploy();

  await usdt.deployed();

  console.log(`Deployed to ${usdt.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

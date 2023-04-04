require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  abiExporter: {
    path: "./abi",
    clear: false,
    flat: true,
  },
  solidity: {
    compilers: [
      {
        version: "0.4.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.1",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    bscTestnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [
        "2d0ea069297c05c5a7443b9f0b32b2087db90fce453aa47342862ee572612f36",
      ],
    },
    goerli: {
      url: `https://goerli.blockpi.network/v1/rpc/public`,
      accounts: [
        "2d0ea069297c05c5a7443b9f0b32b2087db90fce453aa47342862ee572612f36",
      ],
    },
  },
  etherscan: {
    apiKey: {
      bscTestnet: "WHT4G5RK1PKC439WKJICI4G8F51DWUQGYK",
      goerli: "QSYNYXSM5FMNETHTHU2KI6BA2ISWJ1AAIF",
    },
  },
};

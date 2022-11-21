import '@typechain/hardhat';
import "@nomiclabs/hardhat-etherscan";
import "dotenv/config";
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-truffle5';
import '@nomicfoundation/hardhat-chai-matchers';

import { HardhatUserConfig } from 'hardhat/types'


const { API_URL, PRIVATE_KEY, ETHERSCAN_API_URL } = process.env;


const config : HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ],
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${API_URL}`,
      accounts: [`${PRIVATE_KEY}`],
    },
    coston: {
      url: "https://coston-api.flare.network/ext/bc/C/rpc",
      accounts: [`${PRIVATE_KEY}`],
      chainId: 16
    },
    songbird: {
      url: "https://songbird-api.flare.network/ext/bc/C/rpc",
      accounts: [`${PRIVATE_KEY}`],
      chainId: 19
    },
    coston2: {
      url: "https://coston2-api.flare.network/ext/C/rpc",
      accounts: [`${PRIVATE_KEY}`],
      chainId: 114,
    },
    flare: {
      url: "https://flare-api.flare.network/ext/C/rpc",
      accounts: [`${PRIVATE_KEY}`],
      chainId: 14,
    }
  },
  etherscan: {
    apiKey: {
      "goerli": `${ETHERSCAN_API_URL}`,
      "coston": "ABC",
      "coston2": "ABC",
      "songbird": "ABC",
      "flare": "ABC",
    },
    customChains: [
      {
        // https://faucet.towolabs.com/
        network: "coston",
        chainId: 16,
        urls: {
          apiURL: "https://coston-explorer.flare.network/api", // Must not have / endpoint
          browserURL: "https://coston-explorer.flare.network",
        }
      },
      {
        network: "songbird",
        chainId: 19,
        urls: {
          apiURL: "https://songbird-explorer.flare.network/api", // Must not have / endpoint
          browserURL: "https://songbird-explorer.flare.network/",
        }
      },
      {
        // https://coston2-faucet.towolabs.com/
        network: "coston2",
        chainId: 114,
        urls: {
          apiURL: "https://coston2-explorer.flare.network/api",
          browserURL: "https://coston2-explorer.flare.network/",
        }
      },
      {
        network: "flare",
        chainId: 14,
        urls: {
          apiURL: "https://flare-explorer.flare.network/api",
          browserURL: "https://flare-explorer.flare.network/",
        }
      }
    ]
  },
  typechain: {
    target: 'truffle-v5',
  },
};

export default config;

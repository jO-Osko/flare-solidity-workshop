import { artifacts, ethers } from 'hardhat';
import { MultiChainNftContract } from '../typechain-types';

const MultiChainNft: MultiChainNftContract = artifacts.require('MultiChainNft')

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const token = await MultiChainNft.new("Multi Chain Flare NFT", "MCFNFT", "100", { from: deployer.address });
    console.log("Token address:", token.address);
}
main().then(() => process.exit(0))

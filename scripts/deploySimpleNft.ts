import { artifacts, ethers } from 'hardhat'
import { SimpleNFTContract } from '../typechain-types'

const SimpleNFT: SimpleNFTContract = artifacts.require('SimpleNFT')

async function main(){
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const token = await SimpleNFT.new("XKCD Token", "FXKCD", "1000000000000000000", {from: deployer.address});  
    console.log("Token address:", token.address);
    await token.mint({from: deployer.address, value: "1000000000000000000"});
    await token.mint({from: deployer.address, value: "1000000000000000000"});
    await token.mint({from: deployer.address, value: "1000000000000000000"});
    await token.mint({from: deployer.address, value: "1000000000000000000"});

}
main().then(() => process.exit(0))

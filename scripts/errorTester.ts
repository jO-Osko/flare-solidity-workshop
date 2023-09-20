import { artifacts, ethers } from 'hardhat'
import { TesterContract } from '../typechain-types'

const SimpleNFT: TesterContract = artifacts.require('Tester')

async function main(){
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const token = await SimpleNFT.new("0xafBD766c7C3667CB6b4aa32b1AA0b328F3E4473c")
    console.log("Token address:", token.address);
    console.log("Minting 1");
    // console.log(await token.errorC.call());
    console.log("After");
    console.log(await token.errorC());

}
main().then(() => process.exit(0))

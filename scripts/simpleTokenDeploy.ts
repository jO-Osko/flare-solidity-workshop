import { artifacts, ethers } from 'hardhat'
import { TokenContract, TokenInstance } from '../typechain-types'
const Token: TokenContract = artifacts.require('Token')
async function main(){
    const [deployer] = await ethers.getSigners();
    const secondAddress = "0xc8A0d7Fbe75effc3988b9E295614cc4b3479C5A8";
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const token = await Token.new(1000, {from: deployer.address});  
    console.log("Token address:", token.address);
    const token2 = await Token.at(token.address);
    await token2.transfer(secondAddress, 100, {from: deployer.address});
    console.log("Token balance:", (await token2.balanceOf(deployer.address)).toString());
    console.log("Token balance:", (await token2.balanceOf(secondAddress)).toString());
}
main().then(() => process.exit(0))
import { ethers } from 'hardhat';
import { BN } from "bn.js";
import { expect } from 'chai';
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { expectRevert } = require('@openzeppelin/test-helpers');

import { 
    NFTAttackerContract, AttackableSimpleNFTContract, AttackableSimpleNFTInstance
} from '../typechain-types/'


const NFTAttacker: NFTAttackerContract = artifacts.require("NFTAttacker");
const AttackableSimpleNFT: AttackableSimpleNFTContract = artifacts.require("TestableAttackableSimpleNFT");

function bn(n: any){
    return new BN(n.toString());
}


describe('NFT reentrancy attack', async () => {

    const nftPrice = bn(100)
    const maxNftSupply = bn(3)

    let deployer1: SignerWithAddress
    let deployer2: SignerWithAddress
    let deployer3: SignerWithAddress

    let nftToken: AttackableSimpleNFTInstance

    beforeEach(async () => {
        [deployer1, deployer2, deployer3] = await ethers.getSigners();
        nftToken = await AttackableSimpleNFT.new("", "", nftPrice, maxNftSupply, {from: deployer1.address});
    })

    it("Should not mint more than specified tokens normally", async () => {
        for(let i = 0; i < maxNftSupply.toNumber(); i++){
            await nftToken.mint({from: deployer1.address, value: nftPrice});
        }
        await expectRevert(
            nftToken.mint({from: deployer1.address, value: nftPrice}), "No tokens left"
        )

    })

    it("Should be attackable", async () => {
        
        const attacker = await NFTAttacker.new({from: deployer2.address});
        const targetNftNumber = maxNftSupply.mul(bn(2));
        
        expect(targetNftNumber).greaterThan(maxNftSupply);

        await attacker.resetMintTarget(targetNftNumber, nftPrice,  {from: deployer2.address});
        await attacker.send(nftPrice.mul(targetNftNumber).mul(bn(10)), {from: deployer2.address});

        await attacker.startAttack(nftToken.address, {from: deployer2.address});

        console.log("Attacker balance: ", (await nftToken.balanceOf(attacker.address)).toString())
        console.log("Max available nfts: ", (await nftToken.maxTokens()).toString())
        console.log("Minted NFT-s: ", (await nftToken.currentToken()).toString())
        for(let i = 1; i < targetNftNumber.toNumber() + 1; i++){
            expect(await nftToken.ownerOf(i)).to.equal(attacker.address);
        }
        
        // Check that tokens can be transferred
        for(let i = 1; i < targetNftNumber.toNumber() + 1; i++){
            await attacker.transferTo(nftToken.address, deployer3.address, i);
        }

        for(let i = 1; i < targetNftNumber.toNumber() + 1; i++){
            expect(await nftToken.ownerOf(i)).to.equal(deployer3.address);
        }

    })

})

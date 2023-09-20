import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BN } from "bn.js";
import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

import { FCFCollectiblesContract, FCFCollectiblesInstance } from '../typechain-types/';

const TestableSimpleNFT: FCFCollectiblesContract = artifacts.require("TestableSimpleNFT");

function bn(n: any) {
    return new BN(n.toString());
}


describe('Dynamic token', async () => {
    let owner: SignerWithAddress

    let simpleNFT: FCFCollectiblesInstance


    beforeEach(async () => {
        [owner] = await ethers.getSigners();

        const mc = await upgrades.deployProxy(TestableSimpleNFT)
        await mc.deployed()
        // await testableToken.initialize()

    })

    describe("Minting", async () => {

        it("Should mint an NFT", async () => {
            await simpleNFT.mint({ value: 1000 });
            const balance = await simpleNFT.balanceOf(owner.address);
            expect(balance).to.equal(bn(1));
        })

        it("Should mint multiple NFTS", async () => {
            for (let a = 0; a < 10; a++) {
                await simpleNFT.mint({ value: 1000 });
                console.log(await simpleNFT.tokenURI(a + 1));
            }
            const balance = await simpleNFT.balanceOf(owner.address);
            expect(balance).to.equal(bn(10));
        })
    })
})

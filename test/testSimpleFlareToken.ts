import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai from 'chai';
import { artifacts, ethers } from 'hardhat';
const { expect } = chai

import {
    DynamicTokenInstance, GatewayPriceSubmitterContract, GatewayPriceSubmitterInstance, MockFtsoRegistryContract, MockFtsoRegistryInstance, TestableDynamicTokenContract
} from '../typechain-types/';

const TestableDynamicToken: TestableDynamicTokenContract = artifacts.require("TestableDynamicToken");
const GatewayPriceSubmitter: GatewayPriceSubmitterContract = artifacts.require("GatewayPriceSubmitter");
const MockFtsoRegistry: MockFtsoRegistryContract = artifacts.require("MockFtsoRegistry");

const BN = ethers.BigNumber.from;

describe('Dynamic token', async () => {
    let owner: SignerWithAddress

    let dynamicToken: DynamicTokenInstance
    let priceSubmitter: GatewayPriceSubmitterInstance
    let ftsoRegistry: MockFtsoRegistryInstance

    beforeEach(async () => {
        [owner] = await ethers.getSigners();
        const testableToken = await TestableDynamicToken.new(
            100_000_00,
            "Dynamic Flare token",
            "DTOK",
            2, // 2 Decimals
            "SGB",
            "BTC",
            12 // 12 token per each 
        );
        dynamicToken = testableToken;
        priceSubmitter = await GatewayPriceSubmitter.new();
        ftsoRegistry = await MockFtsoRegistry.new();
        await priceSubmitter.setFtsoRegistry(ftsoRegistry.address);
        await testableToken.setPriceSubmitter(priceSubmitter.address);
    })

    describe("Minting", async () => {
        beforeEach(async () => {
            await ftsoRegistry.setSupportedIndices([0, 1, 2], ["BTC", "SGB", "FLR"]);
        })

        it("Should mint an amount of tokens", async () => {
            await ftsoRegistry.setPriceForSymbol("BTC", 2, 0, 5);

            await ftsoRegistry.setPriceForSymbol("SGB", 1, 0, 5);

            const before = await dynamicToken.balanceOf(owner.address);

            const result = await dynamicToken.mint(
                {
                    from: owner.address, value: BN("1065000000000000").
                        add(BN(5).mul(BN(10).pow(BN(18))))
                }
            )

            const after = await dynamicToken.balanceOf(owner.address);

            expect(
                after
            ).to.equal(BN(3000), "Invalid amount of token transferred");

        })
    })
})
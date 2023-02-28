import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai from 'chai';
import { artifacts, ethers } from 'hardhat';
const { expect } = chai
const { time } = require('@openzeppelin/test-helpers');

import {
    GatewayPriceSubmitterContract, GatewayPriceSubmitterInstance,
    MockFtsoManagerContract, MockFtsoManagerInstance,
    MockFtsoRegistryContract, MockFtsoRegistryInstance,
    PricePredictionVaultContract, PricePredictionVaultInstance
} from '../typechain-types';

const TestablePricePredictionVault: PricePredictionVaultContract = artifacts.require("TestablePricePredictionVault");
const GatewayPriceSubmitter: GatewayPriceSubmitterContract = artifacts.require("GatewayPriceSubmitter");
const MockFtsoManager: MockFtsoManagerContract = artifacts.require("MockFtsoManager");
const MockFtsoRegistry: MockFtsoRegistryContract = artifacts.require("MockFtsoRegistry");

async function calcGasCost(result: Truffle.TransactionResponse<any>) {
    // Get the transaction
    let tr = await web3.eth.getTransaction(result.tx);
    // Compute the gas cost of the depositResult
    let txCost = BN(result.receipt.gasUsed).mul(BN(tr.gasPrice));
    return txCost;
};

async function getTime(): Promise<number> {
    await time.advanceBlock();
    const blockNum = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock(blockNum);
    const timestamp = block.timestamp;
    return timestamp
}


const BN = ethers.BigNumber.from;

describe('Prediction Vault', async () => {
    let owner: SignerWithAddress
    let addr1: SignerWithAddress
    let addr2: SignerWithAddress

    let vault: PricePredictionVaultInstance

    let priceSubmitter: GatewayPriceSubmitterInstance
    let ftsoRegistry: MockFtsoRegistryInstance
    let ftsoManager: MockFtsoManagerInstance

    beforeEach(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        const tVault = await TestablePricePredictionVault.new();
        vault = tVault;
        priceSubmitter = await GatewayPriceSubmitter.new();
        ftsoRegistry = await MockFtsoRegistry.new();
        ftsoManager = await MockFtsoManager.new(await getTime() - 100, "180");
        await priceSubmitter.setFtsoManager(ftsoManager.address);
        await priceSubmitter.setFtsoRegistry(ftsoRegistry.address);
        await tVault.setPriceSubmitter(priceSubmitter.address);
    })

    describe("Liquidation", async () => {
        beforeEach(async () => {
            await ftsoRegistry.setSupportedIndices([0, 1, 2], ["BTC", "SGB", "FLR"]);
        })

        it("Should liquidate if correct prediction", async () => {
            await ftsoRegistry.setPriceForSymbol("BTC", 2, 0, 5);
            await ftsoRegistry.setPriceForSymbol("SGB", 4, 0, 5);
            const addr1Start = BN(await web3.eth.getBalance(addr1.address));
            const tx0 = await vault.makePredictionOffer(
                "BTC", "SGB", 3, 2, 10, { value: 100, from: addr1.address }
            )
            const c0 = await calcGasCost(tx0)

            const tx1 = await vault.acceptPredictionOffer(0, { value: 100 * 10, from: addr2.address });
            const c1 = await calcGasCost(tx1);

            await time.increase(180 * 2);

            const tx2 = await vault.liquidatePrediction(0);
            const c2 = await calcGasCost(tx2);

            expect(
                addr1Start.sub(c0).add(BN(1000))
            ).to.equal(BN((await web3.eth.getBalance(addr1.address))),
                "Invalid amount of token transferred");
        })

        it("Should liquidate to acceptor if incorrect prediction", async () => {
            await ftsoRegistry.setPriceForSymbol("BTC", 1, 0, 5);
            await ftsoRegistry.setPriceForSymbol("SGB", 4, 0, 5);
            const addr2Start = BN(await web3.eth.getBalance(addr2.address));
            const tx0 = await vault.makePredictionOffer(
                "BTC", "SGB", 3, 2, 10, { value: 100, from: addr1.address }
            )
            const c0 = await calcGasCost(tx0)

            const tx1 = await vault.acceptPredictionOffer(0, { value: 100 * 10, from: addr2.address });
            const c1 = await calcGasCost(tx1);

            await time.increase(180 * 2);

            const tx2 = await vault.liquidatePrediction(0);
            const c2 = await calcGasCost(tx2);

            expect(
                addr2Start.sub(c1).add(BN(100))
            ).to.equal(BN((await web3.eth.getBalance(addr2.address))),
                "Invalid amount of token transferred");
        })
    })
})
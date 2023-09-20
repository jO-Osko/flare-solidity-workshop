import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BN } from "bn.js";
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { GatewayPriceSubmitterContract, GatewayPriceSubmitterInstance, MockFtsoContract, MockFtsoInstance, MockFtsoRegistryContract, MockFtsoRegistryInstance, TestableSimpleNFTContract, TestableSimpleNFTInstance } from '../typechain-types/';

const TestableSimpleNFT: TestableSimpleNFTContract = artifacts.require("TestableSimpleNFT");
const GatewayPriceSubmitter: GatewayPriceSubmitterContract = artifacts.require("@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockPriceSubmitter.sol:GatewayPriceSubmitter");
const MockFtsoRegistry: MockFtsoRegistryContract = artifacts.require("@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockFtsoRegistry.sol:MockFtsoRegistry");
const MockFtso: MockFtsoContract = artifacts.require("@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockFtso.sol:MockFtso");

function bn(n: any) {
  return new BN(n.toString());
}


describe('Dynamic token', async () => {
  let owner: SignerWithAddress

  let simpleNFT: TestableSimpleNFTInstance
  let priceSubmitter: GatewayPriceSubmitterInstance
  let ftsoRegistry: MockFtsoRegistryInstance
  let btcFTSO: MockFtsoInstance

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    const testableToken = await TestableSimpleNFT.new(
      "Flare XKCD Nft",
      "FXKCD",
      1000
    );
    simpleNFT = testableToken;
    priceSubmitter = await GatewayPriceSubmitter.new();
    ftsoRegistry = await MockFtsoRegistry.new();
    btcFTSO = await MockFtso.new("BTC");
    await btcFTSO.setCurrentRandom(bn(100), bn(0));
    await ftsoRegistry.addFtso(btcFTSO.address);
    await priceSubmitter.setFtsoRegistry(ftsoRegistry.address);
    await testableToken.setPriceSubmitter(priceSubmitter.address);

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

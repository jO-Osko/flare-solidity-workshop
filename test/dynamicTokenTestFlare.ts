import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BN } from "bn.js";
import { expect } from 'chai';
import { ethers } from 'hardhat';

import {
  DynamicTokenFlareInstance, GatewayPriceSubmitterContract, GatewayPriceSubmitterInstance, MockFtsoRegistryContract, MockFtsoRegistryInstance, TestableDynamicTokenFlareContract
} from '../typechain-types/';

const TestableDynamicToken: TestableDynamicTokenFlareContract = artifacts.require("TestableDynamicTokenFlare");
const GatewayPriceSubmitter: GatewayPriceSubmitterContract = artifacts.require("@flarenetwork/flare-periphery-contracts/flare/mockContracts/MockPriceSubmitter.sol:GatewayPriceSubmitter");
const MockFtsoRegistry: MockFtsoRegistryContract = artifacts.require("@flarenetwork/flare-periphery-contracts/flare/mockContracts/MockFtsoRegistry.sol:MockFtsoRegistry");


const MultiChainNft = artifacts.require("MultiChainNft")

function bn(n: any) {
  return new BN(n.toString());
}


describe('Dynamic token', async () => {
  let owner: SignerWithAddress

  let dynamicToken: DynamicTokenFlareInstance
  let priceSubmitter: GatewayPriceSubmitterInstance
  let ftsoRegistry: MockFtsoRegistryInstance

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    const testableToken = await TestableDynamicToken.new(
      10000000,
      "Dynamic Flare token",
      "DTOK",
      2, // 2 Decimals
      "FLR",
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
      await ftsoRegistry.setSupportedIndices([0, 1, 2], ["BTC", "FLR", "FLR"]);
    })

    it("Should mint an amount of tokens", async () => {

      const nft = await MultiChainNft.new("X", "X", 199)
      console.log("HAsh", (await nft.calculateAddressHash("rPTFDJyTJT68hsPigkS8Wn78mubzJJBhT7")))

      await ftsoRegistry.setPriceForSymbol("BTC", 2, 0, 5);

      await ftsoRegistry.setPriceForSymbol("FLR", 1, 0, 5);

      const before = await dynamicToken.balanceOf(owner.address);

      const result = await dynamicToken.mint(
        { from: owner.address, value: bn("1065000000000000").add(bn(5).mul(bn(10).pow(bn(18)))) }
      )

      const after = await dynamicToken.balanceOf(owner.address);

      expect(
        after
      ).to.equal(bn(3000), "Invalid amount of token transferred");

    })
  })
})

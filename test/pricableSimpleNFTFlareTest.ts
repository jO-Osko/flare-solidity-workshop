import { ethers } from 'hardhat';
import { BN } from "bn.js";
import { expect } from 'chai';
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TestablePricableSimpleNFTContract,
    PricableSimpleNFTContractInstance,
    GatewayPriceSubmitterInstance, GatewayPriceSubmitterContract,
    MockFtsoRegistryInstance, MockFtsoRegistryContract
} from '../typechain-types/'

const TestablePricableSimpleNFT: TestablePricableSimpleNFTContract = artifacts.require("TestablePricableSimpleNFT");
const GatewayPriceSubmitter: GatewayPriceSubmitterContract = artifacts.require("@flarenetwork/flare-periphery-contracts/flare/mockContracts/MockPriceSubmitter.sol:GatewayPriceSubmitter");
const MockFtsoRegistry: MockFtsoRegistryContract = artifacts.require("@flarenetwork/flare-periphery-contracts/flare/mockContracts/MockFtsoRegistry.sol:MockFtsoRegistry");

function bn(n: any){
    return new BN(n.toString());
}


describe('Pricable simple NFT', async () => {
  let owner: SignerWithAddress

  let dynamicToken: PricableSimpleNFTContractInstance
  let priceSubmitter: GatewayPriceSubmitterInstance
  let ftsoRegistry: MockFtsoRegistryInstance

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    const testableToken = await TestablePricableSimpleNFT.new(
        "FLR",
        "Dynamic Flare NFT",
        "DFLRNFT",
        "10"
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
      await ftsoRegistry.setPriceForSymbol("BTC", 2, 10, 5);

      await ftsoRegistry.setPriceForSymbol("FLR", 10000, 110, 5);

      const before = await dynamicToken.balanceOf(owner.address);

      console.log("Before", (await dynamicToken.getTokenPriceInNative()).toString());

      const result = await dynamicToken.mint(
        {from: owner.address, value: bn("1065000000000000").add(bn(5).mul(bn(10).pow(bn(18))))}
      )

      const after = await dynamicToken.balanceOf(owner.address);

      expect(
        after
      ).to.equal(bn(3000), "Invalid amount of token transferred");

    })
  })
})

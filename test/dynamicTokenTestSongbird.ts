import { ethers } from 'hardhat';
import { BN } from "bn.js";
import { expect } from 'chai';
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TestableDynamicTokenSongbirdContract, 
    DynamicTokenSongbirdInstance, 
    GatewayPriceSubmitterInstance, GatewayPriceSubmitterContract, 
    MockFtsoRegistryInstance, MockFtsoRegistryContract 
} from '../typechain-types/'

const TestableDynamicToken: TestableDynamicTokenSongbirdContract = artifacts.require("TestableDynamicTokenSongbird");
const GatewayPriceSubmitter: GatewayPriceSubmitterContract = artifacts.require("@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockPriceSubmitter.sol:GatewayPriceSubmitter");
const MockFtsoRegistry: MockFtsoRegistryContract = artifacts.require("@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockFtsoRegistry.sol:MockFtsoRegistry");

function bn(n: any){
    return new BN(n.toString());
}


describe('Dynamic token', async () => {
  let owner: SignerWithAddress

  let dynamicToken: DynamicTokenSongbirdInstance
  let priceSubmitter: GatewayPriceSubmitterInstance
  let ftsoRegistry: MockFtsoRegistryInstance

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    const testableToken = await TestableDynamicToken.new(
        10000000,
        "Dynamic Songbird token",
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
      await ftsoRegistry.setPriceForSymbol("BTC", 2, 0);

      await ftsoRegistry.setPriceForSymbol("SGB", 1, 0);

      const before = await dynamicToken.balanceOf(owner.address);

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

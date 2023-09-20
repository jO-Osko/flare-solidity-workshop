import { ethers } from 'hardhat';
import { BN } from "bn.js";
import { expect } from 'chai';
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


import { TokenContract, TokenInstance } from '../typechain-types/'

const Token: TokenContract = artifacts.require('Token')

function bn(n: any){
    return new BN(n.toString());
}

const totalSupply = bn("10").pow(bn("19"));

describe('Token', async () => {
  let token: TokenInstance
  let owner: SignerWithAddress

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    token = await Token.new(totalSupply)
  })

  describe("Deployment", async () => {
    it("Should set the total supply of tokens and owner", async () => {
      expect(
        await token.totalSupply()
      ).to.equal(totalSupply, "Invalid total supply");

      expect(
        await token.balanceOf(owner.address)
      ).to.equal(totalSupply, "Invalid owner balance");
    })
  })

  it('Should transfer', async () => {

    const [_, addr1] = await ethers.getSigners();

    expect(
      await token.balanceOf(owner.address)
    ).to.equal(totalSupply, "Invalid owner balance");

    // Address should have no balance
    expect(
      await token.balanceOf(addr1.address)
    ).to.equal(bn(0), "Invalid owner balance");

    const amountToTransfer = bn("1000")

    // Transfer token to addr1
    await token.transfer(addr1.address, amountToTransfer, { from: owner.address });

    expect(
      await token.balanceOf(owner.address)
    ).to.equal(totalSupply.sub(amountToTransfer), "Invalid owner balance");

    expect(
      await token.balanceOf(addr1.address)
    ).to.equal(amountToTransfer, "Invalid owner balance");

  })

  it('Should revert on error', async () => {

    const [_, addr1] = await ethers.getSigners();

    expect(
      token.transfer(addr1.address, totalSupply.add(bn(10)), { from: owner.address })
    ).to.be.reverted;

  })

})
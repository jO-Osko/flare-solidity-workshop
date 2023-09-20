import { ethers } from 'hardhat';
import { BN } from "bn.js";
import { expect } from 'chai';
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { time, expectEvent } = require("@openzeppelin/test-helpers");

import { ImprovedVaultInstance } from '../typechain-types/'
const ImprovedVault = artifacts.require('ImprovedVault')


function bn(n: any){
    return new BN(n.toString());
}

const timeLock = 1000 

async function calcGasCost(result: Truffle.TransactionResponse<any>) {
  let tr = await web3.eth.getTransaction(result.tx);
  let txCost = bn(result.receipt.gasUsed).mul(bn(tr.gasPrice));
  return txCost;
};


describe('ImprovedVault', async () => {
  let improvedVault: ImprovedVaultInstance
  let owner: SignerWithAddress
  let secondAccount: SignerWithAddress

  beforeEach(async () => {
    [owner, secondAccount] = await ethers.getSigners();
    improvedVault = await ImprovedVault.new(timeLock);
  })

  describe("Sending", async () => {
    it("Should deposit and emit event", async () => {
        const balanceBefore = bn(await web3.eth.getBalance(owner.address));
        
        const tx = await improvedVault.deposit({from: owner.address, value: 123});

        await expectEvent(tx, "Deposit", {sender: owner.address, amountWei: bn(123)});

        const balanceAfter = bn(await web3.eth.getBalance(owner.address));

        // Balance must change
        expect(balanceBefore).to.greaterThan(balanceAfter);

        expect(balanceBefore).to.equal(
          balanceAfter.add(bn(123)).add(await calcGasCost(tx))
        );
    })

  })

  describe("Withdraw", async () => {
    it("Should deposit and withdraw after enough time to owner address", async () => {
      const balanceBefore = bn(await web3.eth.getBalance(owner.address));
      const txDeposit = await improvedVault.deposit({from: owner.address, value: 123});
      const balanceAfter = bn(await web3.eth.getBalance(owner.address));

      // Balance must change
      expect(balanceBefore).to.greaterThan(balanceAfter);

      expect(balanceBefore).to.equal(
        balanceAfter.add(bn(123)).add(await calcGasCost(txDeposit))
      );

      await time.increase(timeLock + 2);

      const txWithdraw = await improvedVault.withdraw([],{from: owner.address});
      
      const balanceAfterWithdraw = bn(await web3.eth.getBalance(owner.address));
      
      // Should have the same amount minus gas costs
      expect(balanceBefore).to.equal(
        (balanceAfterWithdraw).add(await calcGasCost(txDeposit)).add(await calcGasCost(txWithdraw))
      );
    })

    it("Should deposit and withdraw after enough time to multiple addresses", async () => {
      
      await improvedVault.deposit({from: owner.address, value: 123});

      await time.increase(timeLock + 2);

      await improvedVault.allowRecipient(secondAccount.address,{from: owner.address});

      const balanceBefore = bn(await web3.eth.getBalance(secondAccount.address));

      await improvedVault.withdraw([secondAccount.address],{from: owner.address});

      const balanceAfter = bn(await web3.eth.getBalance(secondAccount.address));

      // Should have the same amount minus gas costs
      expect(balanceBefore).to.equal(
        (balanceAfter).sub(bn(123))
      );
    })
  })
})
import { ethers } from 'hardhat';
import { BN } from "bn.js";
import { expect } from 'chai';
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { time, } = require("@openzeppelin/test-helpers");

import { VaultContract, VaultInstance } from '../typechain-types/'
const Vault: VaultContract = artifacts.require('Vault')


function bn(n: any){
    return new BN(n.toString());
}

const timeLock = 1000 

async function calcGasCost(result: Truffle.TransactionResponse<any>) {
  let tr = await web3.eth.getTransaction(result.tx);
  let txCost = bn(result.receipt.gasUsed).mul(bn(tr.gasPrice));
  return txCost;
};


describe('Vault', async () => {
  let vault: VaultInstance
  let owner: SignerWithAddress

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    vault = await Vault.new(timeLock);
  })

  describe("Sending", async () => {
    it("Should deposit", async () => {
        const balanceBefore = bn(await web3.eth.getBalance(owner.address));
        const tx = await vault.deposit({from: owner.address, value: 123});
        tx
        const balanceAfter = bn(await web3.eth.getBalance(owner.address));

        // Balance must change
        expect(balanceBefore).to.greaterThan(balanceAfter);

        expect(balanceBefore).to.equal(
          balanceAfter.add(bn(123)).add(await calcGasCost(tx))
        );
    })
  })

  describe("Withdraw", async () => {
    it("Should deposit by simple send and withdraw after enough time", async () => {
        const balanceBefore = bn(await web3.eth.getBalance(owner.address))

        const txHash = await owner.sendTransaction(
          {to: vault.address, value: 1234}
        );
        const tx = await txHash.wait();

        const depositCost = tx.effectiveGasPrice.mul(tx.gasUsed);

        await time.increase(timeLock + 2);

        const txWithdraw = await vault.withdraw({from: owner.address});

        const balanceAfter = bn(await web3.eth.getBalance(owner.address));
        // Should have the same amount minus gas costs
        expect(balanceBefore).to.equal(
          balanceAfter.add(bn(depositCost)).add(await calcGasCost(txWithdraw))
        );
    })
  })
})
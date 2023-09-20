import { ethers } from 'hardhat';
import { BN } from "bn.js";
import { expect } from 'chai';

import { 
    MyTokenContract
} from '../typechain-types/' 

const MyToken: MyTokenContract = artifacts.require("MyToken");

function bn(n: any){
    return new BN(n.toString());
}

describe("Token contract", function () {
  it("Deployment should assign the total supply of tokens and owner", async function () {
    const [owner] = await ethers.getSigners();
    const totalSupply = bn(10).pow(bn(19));
    const myToken = await MyToken.new(totalSupply, owner.address, {from: owner.address});

    expect(
      await myToken.totalSupply()
    ).to.equal(totalSupply, "Invalid total supply");
    expect(
      await myToken.owner()
    ).to.equal(owner.address, "Invalid owner");
  });
});

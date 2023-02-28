import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai from 'chai';
import { artifacts, ethers } from 'hardhat';
const { expect } = chai
const { time } = require('@openzeppelin/test-helpers');

import {
    DummyAttestationClientContract, SwapManagerContract, SwapManagerInstance
} from '../typechain-types';

const TestableSwapManager: SwapManagerContract = artifacts.require("TestableSwapManager");
const AttestationClient: DummyAttestationClientContract = artifacts.require("DummyAttestationClient");

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

interface Payment {
    stateConnectorRound: number | BN | string;
    merkleProof: string[];
    blockNumber: number | BN | string;
    blockTimestamp: number | BN | string;
    transactionHash: string;
    inUtxo: number | BN | string;
    utxo: number | BN | string;
    sourceAddressHash: string;
    receivingAddressHash: string;
    spentAmount: number | BN | string;
    receivedAmount: number | BN | string;
    paymentReference: string;
    oneToOne: boolean;
    status: number | BN | string;
}

const BN = ethers.BigNumber.from;


function createDummyPayment(receivedAmount: BN, receivingAddress: string) {
    return {
        stateConnectorRound: 0,
        merkleProof: [],
        blockNumber: 0,
        blockTimestamp: 0,
        transactionHash: "0x4e139676743fae5b38e1d122315ab0f0cf9f4e16de7eafa5f7bb84d03849b689",
        inUtxo: 0,
        utxo: 0,
        sourceAddressHash: "0x4e139676743fae5b38e1d122315ab0f0cf9f4e16de7eafa5f7bb84d03849b689",
        receivingAddressHash: receivingAddress,
        spentAmount: receivedAmount.toString(),
        receivedAmount: receivedAmount.toString(),
        paymentReference: "0x4e139676743fae5b38e1d122315ab0f0cf9f4e16de7eafa5f7bb84d03849b689",
        oneToOne: true,
        status: 0,
    }
}

describe('Swap', async () => {
    let owner: SignerWithAddress
    let addr1: SignerWithAddress
    let addr2: SignerWithAddress

    let swapManager: SwapManagerInstance

    beforeEach(async () => {
        [owner, addr1, addr2] = await ethers.getSigners();
        const tSwapManager = await TestableSwapManager.new();
        swapManager = tSwapManager;
        await tSwapManager.setAttestationClient((await AttestationClient.new()).address);
    })

    describe("Swap", async () => {
        beforeEach(async () => {
            // console.log(
            //     await swapManager.calculateAddressHash("DEUNM99Stpjzhuz8ubTaFn53fSxXVrExX3")
            // )
            // console.log(
            //     await swapManager.calculateAddressHash("rHKZ84GyNzUBc6mjvRCKBrhw3kZigJVveH")
            // )
        })

        it("Should confirm both payments", async () => {
            await swapManager.proposeSwap(
                "DOGE", "XRP", "rHKZ84GyNzUBc6mjvRCKBrhw3kZigJVveH",
                2000, 200, { value: 1000, from: addr1.address }
            )

            await swapManager.acceptSwap(0, "DEUNM99Stpjzhuz8ubTaFn53fSxXVrExX3",
                { value: 10000, from: addr2.address })

            await swapManager.provePayment(0,
                createDummyPayment(
                    BN(2000),
                    "0x4e139676743fae5b38e1d122315ab0f0cf9f4e16de7eafa5f7bb84d03849b689"
                ),
                true)
            await swapManager.provePayment(0,
                createDummyPayment(
                    BN(200),
                    "0xe226581d5a711dcc6c2c0fccf043074d9306451acbf32caa47dc05b208e613eb"
                ),
                false)

        })
    })
})
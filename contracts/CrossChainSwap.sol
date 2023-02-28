// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// FTSO system
import {IFtso} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtso.sol";
import {IPriceSubmitter} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IPriceSubmitter.sol";
import {IFtsoRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtsoRegistry.sol";

// State connector
import {IAttestationClient} from "@flarenetwork/flare-periphery-contracts/coston2/stateConnector/interface/IAttestationClient.sol";

contract SwapManager {
    struct Chain {
        string chainAddress;
        string symbol;
        uint256 amount;
        bool done;
    }
    struct Swap {
        address proposer;
        address acceptor;
        uint256 acceptedTimestamp;
        Chain startingChain;
        Chain endingChain;
    }

    Swap[] public proposals;

    uint256 makerLockIn = 1000;
    uint256 takerLockIn = 10000;
    uint256 swapTimeLimit = 6 hours;

    mapping(string => uint32) public chainIds;

    constructor() {
        chainIds["DOGE"] = 2;
        chainIds["XRP"] = 3;
    }

    function proposeSwap(
        string memory sourceChain,
        string memory targetChain,
        string memory targetChainAddress,
        uint256 sourceValue,
        uint256 targetValue
    ) public payable {
        require(msg.value >= makerLockIn, "Must pay lock in");
        proposals.push(
            Swap(
                msg.sender,
                address(0),
                0,
                Chain("", sourceChain, sourceValue, false),
                Chain(targetChainAddress, targetChain, targetValue, false)
            )
        );
    }

    function calculateAddressHash(string memory addr)
        public
        pure
        returns (bytes32)
    {
        return keccak256(bytes(addr));
    }

    function acceptSwap(uint256 proposalUid, string memory startingChainAddress)
        public
        payable
    {
        require(msg.value >= takerLockIn, "Must pay lock in");
        Swap storage swap = proposals[proposalUid];
        require(swap.acceptor == address(0), "Must not already be accepted");

        swap.acceptedTimestamp = block.timestamp;
        swap.acceptor = msg.sender;
        swap.startingChain.chainAddress = startingChainAddress;
    }

    function provePayment(
        uint256 proposalUid,
        IAttestationClient.Payment memory payment,
        bool isMaker
    ) public {
        Swap storage swap = proposals[proposalUid];
        require(
            block.timestamp <= swap.acceptedTimestamp + swapTimeLimit,
            "Expired"
        );
        Chain storage chain = isMaker ? swap.startingChain : swap.endingChain;
        require(!chain.done, "Already done");
        require(_checkPayment(chain.symbol, payment), "Invalid payment");

        require(chain.amount <= uint256(payment.receivedAmount), "NOT ENOUGH");
        require(
            calculateAddressHash(chain.chainAddress) ==
                payment.receivingAddressHash,
            "Wrong address"
        );
        chain.done = true;
        // Return lock in amount
        payable((isMaker ? swap.proposer : swap.acceptor)).transfer(
            isMaker ? makerLockIn : takerLockIn
        );
    }

    function liquidateOnNonPayment(uint256 proposalUid, bool isMaker) public {
        Swap storage swap = proposals[proposalUid];
        require(
            block.timestamp > swap.acceptedTimestamp + swapTimeLimit,
            "Not expired yet"
        );
        Chain storage chain = isMaker ? swap.startingChain : swap.endingChain;
        require(!chain.done, "Already done");
        chain.done = true;
        // Return lock in amount
        payable((isMaker ? swap.proposer : swap.acceptor)).transfer(
            isMaker ? makerLockIn : takerLockIn
        );
    }

    function _checkPayment(
        string memory chainSymbol,
        IAttestationClient.Payment memory payment
    ) private view returns (bool) {
        // Verify that the payment is valid
        IAttestationClient attestationClient = getAttestationClient();

        return (
            attestationClient.verifyPayment(chainIds[chainSymbol], payment)
        );
    }

    function getAttestationClient()
        public
        view
        virtual
        returns (IAttestationClient)
    {
        return IAttestationClient(0xa8323646aFDC59270ac00F8B27401EE371535CF7);
    }
}

contract TestableSwapManager is SwapManager {
    address public attestationClientAddress;

    constructor() SwapManager() {}

    function setAttestationClient(address _AttestationClientAddress) external {
        attestationClientAddress = _AttestationClientAddress;
    }

    function getAttestationClient()
        public
        view
        override
        returns (IAttestationClient)
    {
        return IAttestationClient(attestationClientAddress);
    }
}

// Just confirms everything for testing purposes
contract DummyAttestationClient is IAttestationClient {
    function verifyBalanceDecreasingTransaction(
        uint32 _chainId,
        BalanceDecreasingTransaction calldata _data
    ) external view returns (bool _proved) {
        return true;
    }

    function verifyConfirmedBlockHeightExists(
        uint32 _chainId,
        ConfirmedBlockHeightExists calldata _data
    ) external view returns (bool _proved) {
        return true;
    }

    function verifyPayment(uint32 _chainId, Payment calldata _data)
        external
        view
        returns (bool _proved)
    {
        return true;
    }

    function verifyReferencedPaymentNonexistence(
        uint32 _chainId,
        ReferencedPaymentNonexistence calldata _data
    ) external view returns (bool _proved) {
        return true;
    }

    function verifyTrustlineIssuance(
        uint32 _chainId,
        TrustlineIssuance calldata _data
    ) external view returns (bool _proved) {
        return true;
    }
}

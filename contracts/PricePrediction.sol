// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IFtso} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtso.sol";
import {IPriceSubmitter} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IPriceSubmitter.sol";
import {IFtsoRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtsoRegistry.sol";
import {IFtsoManagerGenesis} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/genesis/interface/IFtsoManagerGenesis.sol";

error InsufficientBalance(uint256 available, uint256 required);
error OnylOwner();
error SupplyCeiling();

// A simple contract that uses FTSO-system to offer a prediction market
// Users pose predictions of the form
// Asset X will be priced at least A * asset Y at specific price epoch
// with a confidence ratio of Z (payoff multiplier)
// Other users can accept such predictions and after a price epoch is reached,
// any participant can liquidate the proceedings

contract PricePredictionVault {
    struct Prediction {
        string asset1;
        string asset2;
        uint256 differenceCoefficient;
        uint256 value;
        uint256 targetPriceEpoch;
        uint256 payoffMultiplier;
        uint256 addedTimestamp;
        address owner;
        address acceptor;
    }

    Prediction[] public predictions;

    function makePredictionOffer(
        string memory asset1,
        string memory asset2,
        uint256 differenceCoefficient,
        uint256 targetPriceEpoch,
        uint256 payoffMultiplier
    ) public payable returns (uint256) {
        require(
            getFtsoManager().getCurrentPriceEpochId() < targetPriceEpoch,
            "Target price epoch is in the past"
        );

        Prediction memory prediction = Prediction({
            asset1: asset1,
            asset2: asset2,
            differenceCoefficient: differenceCoefficient,
            value: msg.value,
            targetPriceEpoch: targetPriceEpoch,
            payoffMultiplier: payoffMultiplier,
            addedTimestamp: block.timestamp,
            owner: msg.sender,
            acceptor: address(0)
        });

        uint256 uid = predictions.length;

        predictions.push(prediction);
        return uid;
    }

    function removePredictionOffer(uint256 uid) public {
        Prediction storage prediction = predictions[uid];

        require(
            prediction.owner == msg.sender,
            "Only the owner can remove the prediction"
        );
        require(
            prediction.acceptor == address(0),
            "Prediction already accepted"
        );
        uint256 value = prediction.value;
        delete predictions[uid];
        payable(msg.sender).transfer(value);
    }

    function acceptPredictionOffer(uint256 uid) public payable {
        Prediction storage prediction = predictions[uid];

        require(
            prediction.targetPriceEpoch >
                getFtsoManager().getCurrentPriceEpochId(),
            "Target price epoch is in the past"
        );
        require(
            prediction.acceptor == address(0),
            "Prediction already accepted"
        );
        require(
            prediction.value * prediction.payoffMultiplier == msg.value,
            "Not enough value"
        );

        prediction.acceptor = msg.sender;
    }

    function liquidatePrediction(uint256 uid) public {
        Prediction storage prediction = predictions[uid];

        require(
            prediction.targetPriceEpoch ==
                getFtsoManager().getCurrentPriceEpochId(),
            "Target price epoch is not now"
        );
        require(prediction.acceptor != address(0), "Prediction not accepted");

        IFtsoRegistry ftsoRegistry = IFtsoRegistry(
            address(getPriceSubmitter().getFtsoRegistry())
        );

        (uint256 price1, , uint256 token1Decimals) = ftsoRegistry
            .getCurrentPriceWithDecimals(prediction.asset1);
        (uint256 price2, , uint256 token2Decimals) = ftsoRegistry
            .getCurrentPriceWithDecimals(prediction.asset2);

        uint256 maxDecimals = token1Decimals > token2Decimals
            ? token1Decimals
            : token2Decimals;

        // We are only comparing ratio, so multiplication on both
        // sides is irrelevant
        price1 = price1 * (10**(maxDecimals - token1Decimals));
        price2 = price2 * (10**(maxDecimals - token2Decimals));

        address target;
        uint256 value = prediction.value * (1 + prediction.payoffMultiplier);
        if (price1 * prediction.differenceCoefficient > price2) {
            // Prediction was correct
            target = prediction.owner;
        } else {
            // Prediction was incorrect
            target = prediction.acceptor;
        }
        delete predictions[uid];
        payable(target).transfer(value);
    }

    function getPriceSubmitter() public view virtual returns (IPriceSubmitter) {
        return IPriceSubmitter(0x1000000000000000000000000000000000000003);
    }

    function getFtsoManager() public view returns (IFtsoManagerGenesis) {
        return getPriceSubmitter().getFtsoManager();
    }
}

contract TestablePricePredictionVault is PricePredictionVault {
    address public priceSubmitterAddress;

    constructor() PricePredictionVault() {}

    function setPriceSubmitter(address _priceSubmitterAddress) external {
        priceSubmitterAddress = _priceSubmitterAddress;
    }

    function getPriceSubmitter()
        public
        view
        override
        returns (IPriceSubmitter)
    {
        return IPriceSubmitter(priceSubmitterAddress);
    }
}

// Dummy imports for testing
import {GatewayPriceSubmitter} from "@flarenetwork/flare-periphery-contracts/coston2/mockContracts/MockPriceSubmitter.sol";
import {MockFtsoRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/mockContracts/MockFtsoRegistry.sol";
import {MockFtso} from "@flarenetwork/flare-periphery-contracts/coston2/mockContracts/MockFtso.sol";

contract MockFtsoManager is IFtsoManagerGenesis {
    uint256 public firstPriceEpochStartTs;
    uint256 public priceEpochDurationSeconds;

    constructor(
        uint256 _firstPriceEpochStartTs,
        uint256 _priceEpochDurationSeconds
    ) {
        priceEpochDurationSeconds = _priceEpochDurationSeconds;
        firstPriceEpochStartTs = _firstPriceEpochStartTs;
    }

    function getCurrentPriceEpochId() public view returns (uint256) {
        return
            (block.timestamp - firstPriceEpochStartTs) /
            priceEpochDurationSeconds;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { SimpleNFT, IPriceSubmitter } from "./SimpleNFT.sol";

contract TestableSimpleNFT is SimpleNFT {

    address public priceSubmitterAddress;

    constructor (string memory name_, string memory symbol_, uint256 tokenPrice_) SimpleNFT(name_, symbol_, tokenPrice_) {}

    function setPriceSubmitter(address _priceSubmitterAddress) external {
        priceSubmitterAddress = _priceSubmitterAddress;
    }

    function getPriceSubmitter() public override view returns(IPriceSubmitter) {
        return IPriceSubmitter(priceSubmitterAddress);
    }
}

// Dummy imports for testing
import { GatewayPriceSubmitter } from "@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockPriceSubmitter.sol";
import { MockFtsoRegistry } from "@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockFtsoRegistry.sol";
import { MockFtso } from "@flarenetwork/flare-periphery-contracts/songbird/mockContracts/MockFtso.sol";


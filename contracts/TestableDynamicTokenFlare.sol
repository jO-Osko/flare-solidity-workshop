//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { DynamicTokenFlare, IPriceSubmitter } from "./DynamicTokenFlare.sol";

contract TestableDynamicTokenFlare is DynamicTokenFlare {

    address public priceSubmitterAddress;

    constructor (uint256 _maxSupply, string memory _name, string memory _symbol, uint8 _decimals, string memory _nativeTokenSymbol, string memory _foreignTokenSymbol, uint256 _tokensPerForeignToken) DynamicTokenFlare(_maxSupply, _name, _symbol, _decimals, _nativeTokenSymbol, _foreignTokenSymbol, _tokensPerForeignToken) {}

    function setPriceSubmitter(address _priceSubmitterAddress) external {
        priceSubmitterAddress = _priceSubmitterAddress;
    }

    function getPriceSubmitter() public override view returns(IPriceSubmitter) {
        return IPriceSubmitter(priceSubmitterAddress);
    }
}

// Dummy imports for testing
import { GatewayPriceSubmitter } from "@flarenetwork/flare-periphery-contracts/coston2/mockContracts/MockPriceSubmitter.sol";
import { MockFtsoRegistry } from "@flarenetwork/flare-periphery-contracts/flare/mockContracts/MockFtsoRegistry.sol";
import { MockFtso } from "@flarenetwork/flare-periphery-contracts/flare/mockContracts/MockFtso.sol";


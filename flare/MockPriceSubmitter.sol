// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9;

import "@flarenetwork/flare-periphery-contracts/flare/contracts/genesis/interface/IFtsoGenesis.sol";
import "@flarenetwork/flare-periphery-contracts/flare/contracts/genesis/interface/IFtsoRegistryGenesis.sol";
import "@flarenetwork/flare-periphery-contracts/flare/contracts/genesis/interface/IFtsoManagerGenesis.sol";
import { IPriceSubmitter } from "@flarenetwork/flare-periphery-contracts/flare/contracts/userInterfaces/IPriceSubmitter.sol";

contract GatewayPriceSubmitter is IPriceSubmitter {
    
    IFtsoRegistryGenesis public ftsoRegistryField;
    address public voterWhitelisterField;
    IFtsoManagerGenesis public ftsoManagerField;

    function submitHash(
        uint256 _epochId,
        bytes32 _hashe
    ) override external {
        revert("Not implemented");
    }

    function revealPrices(
        uint256 _epochId,
        uint256[] memory _ftsoIndices,
        uint256[] memory _prices,
        uint256 _randoms
    ) override external {
        revert("Not implemented");
    }

    function setFtsoRegistry(IFtsoRegistryGenesis _ftsoRegistry) external {
        ftsoRegistryField = _ftsoRegistry;
    }

    function setVoterWhitelister(address _voterWhitelister) external {
        voterWhitelisterField = _voterWhitelister;
    }

    function setFtsoManager(IFtsoManagerGenesis _ftsoManager) external {
        ftsoManagerField = _ftsoManager;
    }

    function voterWhitelistBitmap(address _voter) external view returns (uint256){
        revert("Not implemented");
    }

    function getVoterWhitelister() external view returns (address) {
        return voterWhitelisterField;
    }
    function getFtsoRegistry() external view returns (IFtsoRegistryGenesis) {
        return ftsoRegistryField;
    }
    function getFtsoManager() external view returns (IFtsoManagerGenesis) {
        return ftsoManagerField;
    }

    function getCurrentRandom() override external view returns (uint256) {
        revert("Not implemented");
    }

    function getRandom(uint256 _epochId) override external view returns (uint256) {
        revert("Not implemented");
    }

}

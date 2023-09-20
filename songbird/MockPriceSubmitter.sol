// // SPDX-License-Identifier: MIT
// pragma solidity >=0.7.6 <0.9;

// import "../genesis/interface/IFtsoGenesis.sol";
// import "../genesis/interface/IFtsoRegistryGenesis.sol";
// import { IPriceSubmitter } from "../userInterfaces/IPriceSubmitter.sol";

// contract GatewayPriceSubmitter is IPriceSubmitter {
    
//     IFtsoRegistryGenesis public ftsoRegistryField;
//     address public voterWhitelisterField;
//     address public ftsoManagerField;

//     function submitPriceHashes(
//         uint256 _epochId,
//         uint256[] memory _ftsoIndices,
//         bytes32[] memory _hashes
//     ) override external {
//         revert("Not implemented");
//     }

//     function revealPrices(
//         uint256 _epochId,
//         uint256[] memory _ftsoIndices,
//         uint256[] memory _prices,
//         uint256[] memory _randoms
//     ) override external {
//         revert("Not implemented");
//     }

//     function setFtsoRegistry(IFtsoRegistryGenesis _ftsoRegistry) external {
//         ftsoRegistryField = _ftsoRegistry;
//     }

//     function setVoterWhitelister(address _voterWhitelister) external {
//         voterWhitelisterField = _voterWhitelister;
//     }

//     function setFtsoManager(address _ftsoManager) external {
//         ftsoManagerField = _ftsoManager;
//     }

//     function voterWhitelistBitmap(address _voter) external view returns (uint256){
//         revert("Not implemented");
//     }

//     function getVoterWhitelister() external view returns (address) {
//         return voterWhitelisterField;
//     }
//     function getFtsoRegistry() external view returns (IFtsoRegistryGenesis) {
//         return ftsoRegistryField;
//     }
//     function getFtsoManager() external view returns (address) {
//         return ftsoManagerField;
//     }
// }

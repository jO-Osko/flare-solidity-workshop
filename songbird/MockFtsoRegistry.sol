// // SPDX-License-Identifier: MIT
// pragma solidity >=0.7.6 <0.9;
// pragma abicoder v2;

// import "../ftso/interface/IIFtso.sol";
// import "../genesis/interface/IFtsoRegistryGenesis.sol";
// import { IFtsoRegistry } from "../userInterfaces/IFtsoRegistry.sol";

// struct Price {
//     uint256 price;
//     uint256 timestamp;
// }

// contract MockFtsoRegistry is IFtsoRegistry {

//     mapping (bytes32 => Price) public prices;

//     mapping (bytes32 => uint256) public ftsoIndices;
//     mapping (uint256 => string) public ftsoSymbols;
//     uint256[] public supportedIndices;

//     function setSupportedIndices(uint256[] memory _supportedIndices, string[] memory _symbols) external {
//         supportedIndices = _supportedIndices;
//         for (uint256 i = 0; i < _supportedIndices.length; i++) {
//             ftsoIndices[keccak256(abi.encode(_symbols[i]))] = _supportedIndices[i];
//             ftsoSymbols[_supportedIndices[i]] = _symbols[i];
//         }
//     }

//     function setPriceForSymbol(string memory _symbol, uint256 _price, uint256 _timestamp) public {
//         prices[keccak256(abi.encode(_symbol))] = Price(_price, _timestamp);
//     }

//     function setPriceForIndex(uint256 _ftsoIndex, uint256 _price, uint256 _timestamp) public {
//         string memory symbol = ftsoSymbols[_ftsoIndex];
//         setPriceForSymbol(symbol, _price, _timestamp);
//     }

//     function getFtsos(uint256[] memory _indices) 
//         external 
//         view 
//         override
//         returns(IFtsoGenesis[] memory _ftsos)
//     {}

//     function getFtso(uint256 _ftsoIndex)
//         external
//         view
//         override
//         returns (IIFtso _activeFtsoAddress)
//     {}

//     function getFtsoBySymbol(string memory _symbol)
//         external
//         view
//         override
//         returns (IIFtso _activeFtsoAddress)
//     {}

//     function getSupportedIndices()
//         external
//         view
//         override
//         returns (uint256[] memory _supportedIndices)
//     {}

//     function getSupportedSymbols()
//         external
//         view
//         override
//         returns (string[] memory _supportedSymbols)
//     {}

//     function getSupportedFtsos()
//         external
//         view
//         override
//         returns (IIFtso[] memory _ftsos)
//     {}

//     function getFtsoIndex(string memory _symbol)
//         external
//         view
//         override
//         returns (uint256 _assetIndex)
//     {}

//     function getFtsoSymbol(uint256 _ftsoIndex)
//         external
//         view
//         override
//         returns (string memory _symbol)
//     {}

//     function getCurrentPrice(uint256 _ftsoIndex)
//         external
//         view
//         override
//         returns (uint256 _price, uint256 _timestamp)
//     {
//         string memory symbol = ftsoSymbols[_ftsoIndex];
//         return this.getCurrentPrice(symbol);
//     }

//     function getCurrentPrice(string memory _symbol)
//         external
//         view
//         override
//         returns (uint256 _price, uint256 _timestamp)
//     {
//         Price memory price = prices[keccak256(abi.encode(_symbol))];
//         return (price.price, price.timestamp);
//     }

//     function getSupportedIndicesAndFtsos()
//         external
//         view
//         override
//         returns (uint256[] memory _supportedIndices, IIFtso[] memory _ftsos)
//     {}

//     function getSupportedSymbolsAndFtsos()
//         external
//         view
//         override
//         returns (string[] memory _supportedSymbols, IIFtso[] memory _ftsos)
//     {}

//     function getSupportedIndicesAndSymbols()
//         external
//         view
//         override
//         returns (
//             uint256[] memory _supportedIndices,
//             string[] memory _supportedSymbols
//         )
//     {
//         _supportedIndices = supportedIndices;
//     }

//     function getSupportedIndicesSymbolsAndFtsos()
//         external
//         view
//         override
//         returns (
//             uint256[] memory _supportedIndices,
//             string[] memory _supportedSymbols,
//             IIFtso[] memory _ftsos
//         )
//     {}
// }

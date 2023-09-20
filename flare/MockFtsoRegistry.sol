// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9;
pragma abicoder v2;

import "@flarenetwork/flare-periphery-contracts/flare/contracts/ftso/interface/IIFtso.sol";
import "@flarenetwork/flare-periphery-contracts/flare/contracts/genesis/interface/IFtsoRegistryGenesis.sol";
import { IFtsoRegistry } from "@flarenetwork/flare-periphery-contracts/flare/contracts/userInterfaces/IFtsoRegistry.sol";

struct Price {
    uint256 price;
    uint256 timestamp;
}

contract MockFtsoRegistry is IFtsoRegistry {
    IIFtso[] private ftsos;
    mapping (string => Price) public prices;

    mapping (string => uint256) public ftsoIndices;
    mapping (uint256 => string) public ftsoSymbols;
    uint256[] public supportedIndices;

    function addFtso(IIFtso _ftsoContract) external returns(uint256) {
        uint256 index = ftsos.length;
        ftsos.push(_ftsoContract);
        ftsoIndices[_ftsoContract.symbol()] = index;
        ftsoSymbols[index] = _ftsoContract.symbol();
        supportedIndices.push(index);
        return index;
    }
    
    function setSupportedIndices(uint256[] memory _supportedIndices, string[] memory _symbols) external {
        supportedIndices = _supportedIndices;
        ftsos = new IIFtso[](0);
        for (uint256 i = 0; i < _supportedIndices.length; i++) {
            ftsoIndices[_symbols[i]] = _supportedIndices[i];
            ftsoSymbols[_supportedIndices[i]] = _symbols[i];
            ftsos.push(IIFtso(address(0)));
        }

    }

    function setPriceForSymbol(string memory _symbol, uint256 _price, uint256 _timestamp) public {
        prices[_symbol] = Price(_price, _timestamp);
    }

    function setPriceForIndex(uint256 _ftsoIndex, uint256 _price, uint256 _timestamp) public {
        string memory symbol = ftsoSymbols[_ftsoIndex];
        setPriceForSymbol(symbol, _price, _timestamp);
    }

    function getFtsos(uint256[] memory _indices) external view returns(IFtsoGenesis[] memory _ftsos) {
        _ftsos = new IFtsoGenesis[](_indices.length);
        for (uint256 i = 0; i < _indices.length; i++) {
            require(_indices[i] < ftsos.length);
            _ftsos[i] = ftsos[_indices[i]];
        }
    }

    function getFtso(uint256 _ftsoIndex) public view returns(IIFtso _activeFtsoAddress) {
        require(_ftsoIndex < ftsos.length);
        return ftsos[_ftsoIndex];
    }

    function getFtsoBySymbol(string memory _symbol) external view returns(IIFtso _activeFtsoAddress) {
        return getFtso(getFtsoIndex(_symbol));
    }

    function getFtsoIndex(string memory _symbol) public view returns (uint256) {
        uint256 index = ftsoIndices[_symbol];
        require(index > 0, "unknown ftso symbol");
        return index - 1;
    }

    function getSupportedIndices() external view returns(uint256[] memory _supportedIndices) {
        return supportedIndices;
    }

    function getSupportedSymbols()
        external
        view
        override
        returns (string[] memory _supportedSymbols)
    {
        _supportedSymbols = new string[](ftsos.length);
        for (uint256 i = 0; i < supportedIndices.length; i++) {
            _supportedSymbols[i] = ftsoSymbols[i + 1];
        }
    }

    function getSupportedFtsos() external view returns(IIFtso[] memory _ftsos) {
        return ftsos;
    }

    function getFtsoSymbol(uint256 _ftsoIndex)
        external
        view
        override
        returns (string memory _symbol)
    {
        return ftsoSymbols[_ftsoIndex];
    }

    function getCurrentPrice(uint256 _ftsoIndex)
        external
        view
        override
        returns (uint256 _price, uint256 _timestamp)
    {
        string memory symbol = ftsoSymbols[_ftsoIndex];
        return this.getCurrentPrice(symbol);
    }

    function getCurrentPrice(string memory _symbol)
        external
        view
        override
        returns (uint256 _price, uint256 _timestamp)
    {
        Price memory price = prices[_symbol];
        return (price.price, price.timestamp);
    }

    function getSupportedIndicesAndFtsos()
        external
        view
        override
        returns (uint256[] memory _supportedIndices, IIFtso[] memory _ftsos)
    {
        _supportedIndices = supportedIndices;
        _ftsos = ftsos;
    }

    function getSupportedSymbolsAndFtsos()
        external
        view
        override
        returns (string[] memory _supportedSymbols, IIFtso[] memory _ftsos)
    {
        _supportedSymbols = new string[](ftsos.length);
        for (uint256 i = 0; i < supportedIndices.length; i++) {
            _supportedSymbols[i] = ftsoSymbols[i + 1];
        }
        _ftsos = ftsos;
    }

    function getSupportedIndicesAndSymbols()
        external
        view
        override
        returns (
            uint256[] memory _supportedIndices,
            string[] memory _supportedSymbols
        )
    {
        _supportedIndices = supportedIndices;
        _supportedSymbols = new string[](ftsos.length);
        for (uint256 i = 0; i < supportedIndices.length; i++) {
            _supportedSymbols[i] = ftsoSymbols[i + 1];
        }
    }

    function getSupportedIndicesSymbolsAndFtsos()
        external
        view
        override
        returns (
            uint256[] memory _supportedIndices,
            string[] memory _supportedSymbols,
            IIFtso[] memory _ftsos
        )
    {
        _supportedIndices = supportedIndices;
        _supportedSymbols = new string[](ftsos.length);
        for (uint256 i = 0; i < supportedIndices.length; i++) {
            _supportedSymbols[i] = ftsoSymbols[i + 1];
        }
        _ftsos = ftsos;
    }
}

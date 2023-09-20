// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact security@fcf.io
contract FCFCollectibles is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor

    uint256 defaultMaxSupply = 100;
    uint256 defaultPrice = 0.06 ether;
    // Optional mapping for max supply
    mapping(uint256 => uint256) private _maxSupplies;
    // Optional mapping for price
    mapping(uint256 => uint256) private _prices;
    mapping(uint256 => string) private _tokenURIs;

    // constructor() {
    //     // _disableInitializers();
    // }

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_tokenURIs[tokenId]);
    }

    function _setTokenUri(uint256 tokenId, string memory tokenURI)
        public
        onlyOwner
    {
        _tokenURIs[tokenId] = tokenURI;
    }

    function mint(uint256 id, uint256 amount) public payable {
        if (!exists(id) && _getPrice(id) == 0) {
            _setPrice(id, defaultPrice);
        }
        require(amount > 0, "Must mint more than 0.");
        require(amount < 3, "Must mint less than 3.");
        require(
            totalSupply(id) + amount <= _maxSupply(id),
            "Attempting to mint more than the max supply"
        );
        require(
            msg.value == amount * _getPrice(id),
            "Amount sent is less than the mint price"
        );

        uint256 fromBalance = balanceOf(msg.sender, id);
        require(
            fromBalance + amount < 3,
            "Cannot own more than 2 of each per wallet"
        );

        _mint(msg.sender, id, amount, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initializeNewToken(
        uint256 tokenId,
        uint256 maxSupply,
        uint256 price,
        string memory tokenURI
    ) public onlyOwner {
        _setMaxSupply(tokenId, maxSupply);
        _setPrice(tokenId, price);
        _setTokenUri(tokenId, tokenURI);
    }

    function _maxSupply(uint256 tokenId) internal view returns (uint256) {
        return _maxSupplies[tokenId];
    }

    /**
     * @dev Sets `_maxSupply` as the uint256 of `tokenId`.
     */
    function _setMaxSupply(uint256 tokenId, uint256 _supply) public onlyOwner {
        _maxSupplies[tokenId] = _supply;
    }

    function getMaxSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (exists(tokenId)) {
            return _maxSupplies[tokenId];
        }
        return defaultMaxSupply;
    }

    function _getPrice(uint256 tokenId) internal view returns (uint256) {
        return _prices[tokenId];
    }

    /**
     * @dev Sets `_price` as the uint256 of `tokenId`.
     */
    function _setPrice(uint256 tokenId, uint256 _price) public onlyOwner {
        _prices[tokenId] = _price;
    }

    function getPrice(uint256 tokenId) public view virtual returns (uint256) {
        if (exists(tokenId)) {
            return _prices[tokenId];
        }
        return defaultPrice;
    }
}

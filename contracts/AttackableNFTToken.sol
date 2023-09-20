//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// WARNING: This contract is vulnerable to at least one type of commonly known attacks.
// Do not use this code in production.

import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { IFtso } from "@flarenetwork/flare-periphery-contracts/coston/ftso/userInterfaces/IFtso.sol";
import { IPriceSubmitter } from "@flarenetwork/flare-periphery-contracts/coston/ftso/userInterfaces/IPriceSubmitter.sol";
import { IFtsoRegistry } from "@flarenetwork/flare-periphery-contracts/coston/ftso/userInterfaces/IFtsoRegistry.sol";

contract AttackableSimpleNFT is ERC721Enumerable {

    string[14] uidLinks = [
        "ipfs://ipfs/bafkreieybi64qgt2nd24ht7e5bkgcfmallurlyqrtufftbzlh65sei4zrq",
        "ipfs://ipfs/bafkreigxf6kwo7qq2nds4b4vzqhyy7yj37hkdfkwhs24xy6rayvbf5yfgy",
        "ipfs://ipfs/bafkreichupmk6f4uxwvy4izkswlyu3viwlyqaabjwreyd6j3f66tyw33ge",
        "ipfs://ipfs/bafkreidruphdcmqb2s5ibympfmuilpuzd64xj3xlu7sruffy2w7hw3oo4u",
        "ipfs://ipfs/bafkreiadsbrd4knarjarfmcswxye762h5gcfigdk4xqq4wud2rwhnxttsm",
        "ipfs://ipfs/bafkreiat7y3wez6e6autxn73mvjluoxc5gjwzrcjmlrv3outxnm4wdar7m",
        "ipfs://ipfs/bafkreieg6xotxyxetew65fg47iy4peu2vsjjr67raxlz5nkm65ebvolrx4",
        "ipfs://ipfs/bafkreia3j4oparmlz37kzq5msoix55nz25ucsfgsv5euhuss72vrcmin34",
        "ipfs://ipfs/bafkreiawnajxljlztnxyu23hodvysac37seio7scvfwjyb6gqrdomc5gxe",
        "ipfs://ipfs/bafkreigvq7766epo3bhpg67oxfuxlofzjt2a6ht2aj2suwdviwezs4l4mq",
        "ipfs://ipfs/bafkreigniof2fm2ooeiwomvhachcu2kj74rgz43j4665fcff6tkovmqvs4",
        "ipfs://ipfs/bafkreiaqdet3dm2rwpgj4xgi7l2ypefqukanwkeqykajojinuhhbqptpqi",
        "ipfs://ipfs/bafkreidejgskxyv6orhpitmq6oxg4meizm6iqeypvx7yymtdbuel7s3itq",
        "ipfs://ipfs/bafkreieitl5zfhrwvtnu42gcd5mozuqjcbrrv7vwr2ur7nnxcztmemm4yq"
    ];

    uint256 immutable tokenPrice;
    address immutable owner;

    uint256 public mintedTokens = 0;
    uint256 immutable public maxTokens;
    uint256 public currentToken = 0;
    mapping (uint256 => uint256) private tokenUidLinkIndex;

    constructor(string memory name_, string memory symbol_, uint256 tokenPrice_, uint256 maxTokens_) 
        ERC721(name_, symbol_) 
    {
        tokenPrice = tokenPrice_;
        owner = msg.sender;
        maxTokens = maxTokens_;
    }

    // WARNING: Problematic implementation
    function mint() public payable {
        require(msg.value >= tokenPrice, "Not enough coins paid");

        uint256 tokenId = currentToken + 1;
        ++currentToken;
        tokenUidLinkIndex[tokenId] = uint256(keccak256(abi.encode(getCurrentRandom(), tokenId))) % uidLinks.length;
        
        // Check if we can still mint
        require(maxTokens > mintedTokens, "No tokens left");

        _safeMint(msg.sender, tokenId);

        // Increse the number of minted tokens
        ++mintedTokens;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return uidLinks[tokenUidLinkIndex[tokenId]];
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    function getPriceSubmitter() public virtual view returns(IPriceSubmitter) {
        return IPriceSubmitter(0x1000000000000000000000000000000000000003);
    }

    function getCurrentRandom() virtual public view returns(uint256 currentRandom) {
        IFtsoRegistry ftsoRegistry = IFtsoRegistry(address(getPriceSubmitter().getFtsoRegistry()));
        IFtso ftso = IFtso(ftsoRegistry.getFtso(0));
        return ftso.getCurrentRandom();
    }

}

contract TestableAttackableSimpleNFT is AttackableSimpleNFT {

    address public priceSubmitterAddress;

    constructor(string memory name_, string memory symbol_, uint256 tokenPrice_, uint256 maxTokens_) 
        AttackableSimpleNFT(name_, symbol_, tokenPrice_, maxTokens_) 
    {
    }

    function setPriceSubmitter(address _priceSubmitterAddress) external {
        priceSubmitterAddress = _priceSubmitterAddress;
    }

    function getPriceSubmitter() public override view returns(IPriceSubmitter) {
        return IPriceSubmitter(priceSubmitterAddress);
    }

    function getCurrentRandom() public view override returns(uint256 currentRandom) {
        return 10;
    }
}


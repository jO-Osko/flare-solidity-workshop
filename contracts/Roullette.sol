// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { IFtso } from "@flarenetwork/flare-periphery-contracts/songbird/ftso/userInterfaces/IFtso.sol";
import { IPriceSubmitter } from "@flarenetwork/flare-periphery-contracts/songbird/ftso/userInterfaces/IPriceSubmitter.sol";
import { IFtsoManager } from "@flarenetwork/flare-periphery-contracts/songbird/ftso/userInterfaces/IFtsoManager.sol";
import { IFtsoRegistry } from "@flarenetwork/flare-periphery-contracts/songbird/ftso/userInterfaces/IFtsoRegistry.sol";




contract RouletteGame {

    enum BetType { 
        Straight, Row, 
        Split, DoubleStreet,
        Street, Corner,
        SixLine, Trio,
        Basket, LowHigh,
        RedBlack, EvenOdd,
        Dozen, Column,
        Snake 
    }

    struct BetInfo {
        BetType betType;
        uint256 argument;
    }

    struct PlayerBet {
        BetInfo info;
        uint256 betAmount;
    }

    struct Game {
        mapping(address => PlayerBet[]) bets;
        uint256[37] maxPayout;
        uint256 currentMaxPayout;
        uint256 selectedRandom;
    }

    mapping(uint256 => Game) private games;

    address owner;
    uint256 currentBalanceWei;
    uint256 reservedBalanceWei;
    uint256 maxBetWei = 1 ether;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function clearExpiredGame(uint256 gameId) public onlyOwner {
        uint256 currentEpoch = getFtsoManager().getCurrentRewardEpoch();
        require(gameId < currentEpoch - 1, "Game is not expired");
        Game storage game = games[gameId];
        // Todo, rethink this
    }


    function getPriceSubmitter() virtual public view returns(IPriceSubmitter){
        return IPriceSubmitter(0x1000000000000000000000000000000000000003);
    }

    function getFtsoManager() internal view returns (IFtsoManager) {
        return IFtsoManager(getPriceSubmitter().getFtsoManager());
    }

    function _calculatePayout(BetType betType, uint256 betAmount) internal returns (uint256) {
        if(betType == BetType.Straight){
            return betAmount * 36;
        }else if(betType == BetType.Split){
            return betAmount * 18;
        }else if(betType == BetType.Row){
            return betAmount * 18;
        }else if(betType == BetType.Street){
            return betAmount * 12;
        }else if(betType == BetType.Corner){
            return betAmount * 9;
        }else if(betType == BetType.SixLine){
            return betAmount * 6;
        }else if(betType == BetType.Trio){
            return betAmount * 12;
        }else if(betType == BetType.Basket){
            return betAmount * 7;
        }else if(betType == BetType.DoubleStreet){
            return betAmount * 6;
        }else if(betType == BetType.LowHigh){
            return betAmount * 2;
        }else if(betType == BetType.RedBlack){
            return betAmount * 2;
        }else if(betType == BetType.EvenOdd){
            return betAmount * 2;
        }else if(betType == BetType.Dozen){
            return betAmount * 3;
        }else if(betType == BetType.Column){
            return betAmount * 3;
        }else if(betType == BetType.Snake){
            return betAmount * 3;
        }
        assert(false);
    }

    function bet(BetInfo memory betInfo) public payable {
        require(msg.value <= maxBetWei, "Bet is too big");
        uint256 currentEpoch = getFtsoManager().getCurrentRewardEpoch();
        Game storage game = games[currentEpoch];
        game.bets[msg.sender].push(PlayerBet(betInfo, msg.value));
        currentBalanceWei += msg.value;
    }

    function claimWin() public {
        
    }

    function finalizeActiveGame() public {
        _finalizeActiveGame();
    }

    function getRandomForEpoch(uint256 _epochId) public returns(uint256){
        return 1 - _epochId;
    }

    function _finalizeActiveGame() internal {

    }


}
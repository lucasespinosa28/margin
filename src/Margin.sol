// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IMargin} from "./interfaces/IMargin.sol";

contract Margin is IMargin {
    IERC20 collateral;
    IPriceOracle priceOracle;
    uint256 LEVERAGE = 5;
    mapping(address => Position) public positions;
    constructor(IERC20 _collateral, IPriceOracle _priceOracle) {
        collateral = _collateral;
        priceOracle = _priceOracle;
    }

    function openPosition(
          bool isLong,
        uint256 collateralAmount,
        uint256 entryPrice
    ) external override {
        uint256 currentPrice = priceOracle.getPrice();
        collateral.transferFrom(msg.sender, address(this), collateralAmount);
        
        positions[msg.sender] = Position({
            isLong: true,
            collateral: collateralAmount,
            positionSize: collateralAmount * LEVERAGE,
            entryPrice: currentPrice
        });

    //          bool isLong;
    //     uint256 collateral;
    //     uint256 positionSize; // Size of position with leverage applied
    //     uint256 entryPrice; 
    }

    function closePosition() external override {}

    function liquidated() external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMargin {
    struct Position {
        bool isLong;
        uint256 collateral;
        uint256 positionSize; // Size of position with leverage applied
        uint256 entryPrice; // Price when the position was opened
    }

    event PositionClosed(address indexed user, uint256 profitOrLoss);
    event PositionLiquidated(address indexed user, uint256 collateralLost);
    event PositionOpened(
        address indexed user,
        bool isLong,
        uint256 collateralAmount,
        uint256 positionSize,
        uint256 entryPrice
    );
    function openPosition(
        bool isLong,
        uint256 collateralAmount,
        uint256 entryPrice
    ) external;
    function closePosition() external;
    function liquidated() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPriceOracle {
      function getPrice() external view returns (uint256); // Returns ETH/USD price with 18 decimals
}
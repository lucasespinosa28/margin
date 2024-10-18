// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MockPriceFeed  {
    int256 private price;
    uint8 private decimals_;
    string private description_;
    uint256 private version_;

    constructor(int256 _initialPrice, uint8 _decimals) {
        price = _initialPrice;
        decimals_ = _decimals;
        description_ = "Mock Price Feed";
        version_ = 1;
    }

    function setPrice(int256 _price) external {
        price = _price;
    }

    function latestRoundData() external view 
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            uint80(0), // roundId
            price,
            block.timestamp, // startedAt
            block.timestamp, // updatedAt
            uint80(0) // answeredInRound
        );
    }

    function decimals() external view  returns (uint8) {
        return decimals_;
    }

    function description() external view  returns (string memory) {
        return description_;
    }

    function version() external view  returns (uint256) {
        return version_;
    }

    // We don't need historical data for our tests, so we'll leave these unimplemented
    function getRoundData(uint80 _roundId) external pure 
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        revert("Not implemented");
    }

    function latestAnswer() external view returns (int256) {
        return price;
    }

    function latestTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function latestRound() external pure returns (uint256) {
        return 0;
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        if (roundId == 0) {
            return price;
        }
        revert("Round not found");
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        if (roundId == 0) {
            return block.timestamp;
        }
        revert("Round not found");
    }
}
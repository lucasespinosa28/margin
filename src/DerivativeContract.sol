// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeed {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract MockPriceFeed is IPriceFeed {
    int256 private price;
    address private owner;

    constructor() {
        owner = msg.sender;
        price = 100 * 10**8; // Initial price of 100 USD with 8 decimals
    }

    function setPrice(int256 _price) external {
        price = _price;
    }

    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, price, 0, block.timestamp, 0);
    }
}

contract DerivativeContract {
    IERC20 public usdToken;
    IPriceFeed public priceFeed;
    
    uint256 public constant LEVERAGE = 5;
    uint256 public constant LIQUIDATION_THRESHOLD = 80; // 80% of initial margin
    
    struct Position {
        uint256 collateralAmount;
        uint256 entryPrice;
        bool isLong;
    }
    
    mapping(address => Position) public positions;
    
    constructor(address _usdToken, address _priceFeed) {
        usdToken = IERC20(_usdToken);
        priceFeed = IPriceFeed(_priceFeed);
    }
    
    function openPosition(uint256 _collateralAmount, bool _isLong) external {
        require(_collateralAmount > 0, "Collateral must be greater than 0");
        require(usdToken.transferFrom(msg.sender, address(this), _collateralAmount), "Transfer failed");
        
        uint256 currentPrice = getCurrentPrice();
        
        positions[msg.sender] = Position({
            collateralAmount: _collateralAmount,
            entryPrice: currentPrice,
            isLong: _isLong
        });
    }
    
    function closePosition() external {
        Position memory position = positions[msg.sender];
        require(position.collateralAmount > 0, "No open position");
        
        uint256 currentPrice = getCurrentPrice();
        int256 pnl = calculatePnL(position, currentPrice);
        
        uint256 amountToReturn = position.collateralAmount;
        if (pnl > 0) {
            amountToReturn += uint256(pnl);
        } else if (pnl < 0) {
            uint256 loss = uint256(-pnl);
            amountToReturn = loss >= position.collateralAmount ? 0 : position.collateralAmount - loss;
        }
        
        delete positions[msg.sender];
        require(usdToken.transfer(msg.sender, amountToReturn), "Transfer failed");
    }
    
    function liquidate(address _trader) external {
        Position memory position = positions[_trader];
        require(position.collateralAmount > 0, "No open position");
        
        uint256 currentPrice = getCurrentPrice();
        int256 pnl = calculatePnL(position, currentPrice);
        
        uint256 currentValue;
        if (pnl >= 0) {
            currentValue = position.collateralAmount + uint256(pnl);
        } else {
            uint256 loss = uint256(-pnl);
            currentValue = loss >= position.collateralAmount ? 0 : position.collateralAmount - loss;
        }
        
        uint256 liquidationValue = (position.collateralAmount * LIQUIDATION_THRESHOLD) / 100;
        require(currentValue < liquidationValue, "Position is not liquidatable");
        
        delete positions[_trader];
        // In a real implementation, you would distribute the remaining funds to the liquidator and the protocol
    }
    
    function calculatePnL(Position memory _position, uint256 _currentPrice) internal pure returns (int256) {
        int256 priceDiff = int256(_currentPrice) - int256(_position.entryPrice);
        if (!_position.isLong) {
            priceDiff = -priceDiff;
        }
        return (priceDiff * int256(_position.collateralAmount) * int256(LEVERAGE)) / int256(_position.entryPrice);
    }
    
    function getCurrentPrice() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }
}
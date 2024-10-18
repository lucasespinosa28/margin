// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DerivativeContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSD is ERC20 {
    constructor() ERC20("Mock USD", "MUSD") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract DerivativeContractTest is Test {
    DerivativeContract public derivativeContract;
    MockPriceFeed public mockPriceFeed;
    MockUSD public mockUSD;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        mockUSD = new MockUSD();
        mockPriceFeed = new MockPriceFeed();
        derivativeContract = new DerivativeContract(address(mockUSD), address(mockPriceFeed));

        mockUSD.transfer(alice, 10000 * 10**18);
        mockUSD.transfer(bob, 10000 * 10**18);
        // Transfer additional funds to the contract to cover potential profits
        mockUSD.transfer(address(derivativeContract), 100000 * 10**18);

        vm.startPrank(alice);
        mockUSD.approve(address(derivativeContract), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        mockUSD.approve(address(derivativeContract), type(uint256).max);
        vm.stopPrank();
    }

    function testOpenPosition() public {
        vm.startPrank(alice);
        uint256 collateralAmount = 1000 * 10**18;
        derivativeContract.openPosition(collateralAmount, true);

        (uint256 positionCollateral, uint256 entryPrice, bool isLong) = derivativeContract.positions(alice);
        assertEq(positionCollateral, collateralAmount, "Collateral amount should match");
        assertEq(entryPrice, 100 * 10**8, "Entry price should match current price");
        assertTrue(isLong, "Position should be long");
        vm.stopPrank();
    }

    function testClosePosition() public {
        vm.startPrank(alice);
        uint256 collateralAmount = 1000 * 10**18;
        derivativeContract.openPosition(collateralAmount, true);

        // Simulate price increase
        mockPriceFeed.setPrice(110 * 10**8);

        uint256 balanceBefore = mockUSD.balanceOf(alice);
        derivativeContract.closePosition();
        uint256 balanceAfter = mockUSD.balanceOf(alice);

        assertGt(balanceAfter, balanceBefore, "Balance should increase after closing profitable position");
        vm.stopPrank();
    }

    function testLiquidation() public {
        vm.startPrank(alice);
        uint256 collateralAmount = 1000 * 10**18;
        derivativeContract.openPosition(collateralAmount, true);
        vm.stopPrank();

        // Simulate significant price decrease to trigger liquidation
        mockPriceFeed.setPrice(79 * 10**8);

        vm.startPrank(bob);
        derivativeContract.liquidate(alice);

        (uint256 positionCollateral,,) = derivativeContract.positions(alice);
        assertEq(positionCollateral, 0, "Position should be liquidated");
        vm.stopPrank();
    }

    function testFailLiquidationHealthyPosition() public {
        vm.startPrank(alice);
        uint256 collateralAmount = 1000 * 10**18;
        derivativeContract.openPosition(collateralAmount, true);
        vm.stopPrank();

        // Simulate small price decrease, not enough to trigger liquidation
        mockPriceFeed.setPrice(95 * 10**8);

        vm.startPrank(bob);
          vm.expectRevert(bytes("Position is not liquidatable")); 
        derivativeContract.liquidate(alice); // This should fail
        vm.stopPrank();
    }
}
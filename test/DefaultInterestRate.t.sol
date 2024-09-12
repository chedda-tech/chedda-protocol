// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {InterestRates} from "../contracts/interestrates/IInterestRateModel.sol";
import {DefaultInterestRateModel} from "../contracts/interestrates/DefaultInterestRateModel.sol";

contract DefaultInterstRateTest is Test {

    DefaultInterestRateModel public irModel;

    function setUp() public {
        uint256 baseBorrowRate = 0.05e18;
        uint256 rateSlope1 = 0.088e18;
        uint256 rateSlope2 = 8e18;
        uint256 targetUtilization = 0.92e18;
        uint256 feeBps = 0.1e18;
        irModel = new DefaultInterestRateModel(
            baseBorrowRate,
            rateSlope1,
            rateSlope2,
            targetUtilization,
            feeBps
        );
    }

    function testInitialRate() public view {
        InterestRates memory rates = irModel.calculateInterestRates(0);
        assertEq(rates.borrowRate, irModel.baseBorrowRate());
        assertEq(rates.supplyRate, 0);
    }

    function testSlopeIncrease() public view {
        InterestRates memory rates1 = irModel.calculateInterestRates(0.01e18);
        InterestRates memory rates2 = irModel.calculateInterestRates(0.02e18);
        InterestRates memory rates3 = irModel.calculateInterestRates(0.11e18);
        assertEq(rates1.borrowRate + irModel.rateSlope1() / 100, rates2.borrowRate);
        assertEq(rates1.borrowRate + irModel.rateSlope1() / 10, rates3.borrowRate);
    }

    function testSlope2Increase() public view {
        InterestRates memory rates1 = irModel.calculateInterestRates(irModel.targetUtilization());
        InterestRates memory rates2 = irModel.calculateInterestRates(irModel.targetUtilization() + 0.01e18);
        assertEq(rates1.borrowRate + irModel.rateSlope2() / 100, rates2.borrowRate);
    }
}
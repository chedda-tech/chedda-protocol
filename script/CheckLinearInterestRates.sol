// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {LinearInterestRatesModel} from "../contracts/pool/LinearInterestRatesModel.sol";

contract CheckLinearInterestRatesModel is Script {
    LinearInterestRatesModel public strategy;

    function setUp() external {
        uint256 baseSupplyRate = 0.0e18;
        uint256 baseBorrowRate = 0.05e18;
        uint256 steeperSlopeInterestRate = 0.1e18;
        uint256 targetUtilization = 0.94e18;
        strategy = new LinearInterestRatesModel(
            baseSupplyRate,
            baseBorrowRate,
            steeperSlopeInterestRate,
            targetUtilization
        );
    }

    function run() external view {
        console2.log("Interest rate at 0%% = (%d, %d)", strategy.calculateInterestRates(0).supplyRate, strategy.calculateInterestRates(0).borrowRate);
        console2.log("Interest rate at 1%% = (%d, %d)", strategy.calculateInterestRates(0.01e18).supplyRate, strategy.calculateInterestRates(0.01e18).borrowRate);
        console2.log("Interest rate at 2%% = (%d, %d)", strategy.calculateInterestRates(0.02e18).supplyRate, strategy.calculateInterestRates(0.02e18).borrowRate);
        console2.log("Interest rate at 5%% = (%d, %d)", strategy.calculateInterestRates(0.05e18).supplyRate, strategy.calculateInterestRates(0.05e18).borrowRate);
        console2.log("Interest rate at 10%% = (%d, %d)", strategy.calculateInterestRates(0.1e18).supplyRate, strategy.calculateInterestRates(0.1e18).borrowRate);
        console2.log("Interest rate at 20%% = (%d, %d)", strategy.calculateInterestRates(0.2e18).supplyRate, strategy.calculateInterestRates(0.2e18).borrowRate);
        console2.log("Interest rate at 25%% = (%d, %d)", strategy.calculateInterestRates(0.25e18).supplyRate, strategy.calculateInterestRates(0.25e18).borrowRate);
        console2.log("Interest rate at 30%% = (%d, %d)", strategy.calculateInterestRates(0.3e18).supplyRate, strategy.calculateInterestRates(0.3e18).borrowRate);
        console2.log("Interest rate at 50%% = (%d, %d)", strategy.calculateInterestRates(0.5e18).supplyRate, strategy.calculateInterestRates(0.5e18).borrowRate);
        console2.log("Interest rate at 70%% = (%d, %d)", strategy.calculateInterestRates(0.7e18).supplyRate, strategy.calculateInterestRates(0.7e18).borrowRate);
        console2.log("Interest rate at 70%% = (%d, %d)", strategy.calculateInterestRates(0.8e18).supplyRate, strategy.calculateInterestRates(0.8e18).borrowRate);
        console2.log("Interest rate at 90%% = (%d, %d)", strategy.calculateInterestRates(0.9e18).supplyRate, strategy.calculateInterestRates(0.9e18).borrowRate);
        console2.log("Interest rate at 91%% = (%d, %d)", strategy.calculateInterestRates(0.91e18).supplyRate, strategy.calculateInterestRates(0.91e18).borrowRate);
        console2.log("Interest rate at 95%% = (%d, %d)", strategy.calculateInterestRates(0.95e18).supplyRate, strategy.calculateInterestRates(0.95e18).borrowRate);
        console2.log("Interest rate at 97%% = (%d, %d)", strategy.calculateInterestRates(0.97e18).supplyRate, strategy.calculateInterestRates(0.97e18).borrowRate);
        console2.log("Interest rate at 99%% = (%d, %d)", strategy.calculateInterestRates(0.99e18).supplyRate, strategy.calculateInterestRates(0.99e18).borrowRate);
        console2.log("Interest rate at 100%% = (%d, %d)", strategy.calculateInterestRates(1.0e18).supplyRate, strategy.calculateInterestRates(1.0e18).borrowRate);
        console2.log("Interest rate at 110%% = (%d, %d)", strategy.calculateInterestRates(1.1e18).supplyRate, strategy.calculateInterestRates(1.1e18).borrowRate);
    }
}
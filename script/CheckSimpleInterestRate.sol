// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {SimpleInterestRateStrategy} from "../contracts/pool/SimpleInterestRateStrategy.sol";

contract CheckSimpleInterestRateStrategy is Script {

    SimpleInterestRateStrategy public strategy;

    function setUp() external {
        uint256 linearRate = 0.05e18;
        uint256 exponentialRate = 0.00001e18;
        uint256 targetUtilization = 0.94e18;
        strategy = new SimpleInterestRateStrategy(
            linearRate,
            exponentialRate,
            targetUtilization
        );
    }

    function run() external view {
        console2.log("Interest rate at 1%% = %d", strategy.getInterestRate(0.01e18));
        console2.log("Interest rate at 2%% = %d", strategy.getInterestRate(0.02e18));
        console2.log("Interest rate at 5%% = %d", strategy.getInterestRate(0.05e18));
        console2.log("Interest rate at 10%% = %d", strategy.getInterestRate(0.1e18));
        console2.log("Interest rate at 20%% = %d", strategy.getInterestRate(0.2e18));
        console2.log("Interest rate at 25%% = %d", strategy.getInterestRate(0.25e18));
        console2.log("Interest rate at 30%% = %d", strategy.getInterestRate(0.3e18));
        console2.log("Interest rate at 50%% = %d", strategy.getInterestRate(0.5e18));
        console2.log("Interest rate at 70%% = %d", strategy.getInterestRate(0.7e18));
        console2.log("Interest rate at 90%% = %d", strategy.getInterestRate(0.9e18));
        console2.log("Interest rate at 91%% = %d", strategy.getInterestRate(0.91e18));
        console2.log("Interest rate at 95%% = %d", strategy.getInterestRate(0.95e18));
        console2.log("Interest rate at 97%% = %d", strategy.getInterestRate(0.97e18));
        console2.log("Interest rate at 99%% = %d", strategy.getInterestRate(0.99e18));
        console2.log("Interest rate at 100%% = %d", strategy.getInterestRate(1.0e18));
        console2.log("Interest rate at 110%% = %d", strategy.getInterestRate(1.1e18));
    }
}
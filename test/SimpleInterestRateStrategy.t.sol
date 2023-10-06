// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import { SimpleInterestRateStrategy } from "../contracts/pool/SimpleInterestRateStrategy.sol";

contract SimpleInterestRateStrategyTest is Test {

    SimpleInterestRateStrategy public strategy;

    function setUp() external {
        uint256 linearRate = 0.05e18;
        uint256 exponentialRate = 0.1e18;
        uint256 targetUtilization = 0.9e18;
        strategy = new SimpleInterestRateStrategy(
            linearRate,
            exponentialRate,
            targetUtilization
        );
    }

    function testRates() external {

    }
}
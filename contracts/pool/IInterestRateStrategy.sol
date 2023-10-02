// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

struct InterestRates {
    uint256 supplyRate;
    uint256 borrowRate;
}

interface IInterestRateStrategy {

    function calculateInterestRates(
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) external returns (InterestRates memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

struct InterestRates {
    uint256 utilization;
    uint256 supplyRate;
    uint256 borrowRate;
}

interface IInterestRatesModel {
    function calculateInterestRates(uint256 utilization) external view returns (InterestRates memory);
}

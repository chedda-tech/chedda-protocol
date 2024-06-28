// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IInterestRatesModel, InterestRates } from "./IInterestRatesModel.sol";

contract DefaultInterestRateModel is IInterestRatesModel {
    uint256 public baseBorrowRate;  // Initial interest rate
    uint256 public rateSlope1; // rate of increase when utilization <= targetUtilization
    uint256 public rateSlope2; // rate of increase when utilization > targetUtilization
    uint256 public targetUtilization; // Target utilization rate
    uint256 public feeBps;  // Protocol fee

    constructor(
        uint256 _baseBorrowRate,
        uint256 _rateSlope1,
        uint256 _rateSlope2,
        uint256 _targetUtilization,
        uint256 _feeBps
    ) {
        baseBorrowRate = _baseBorrowRate;
        rateSlope1 = _rateSlope1;
        rateSlope2 = _rateSlope2;
        targetUtilization = _targetUtilization;
        feeBps = _feeBps;
    }

    // Calculate the interest rate based on utilization
    function calculateInterestRates(uint256 utilization) public view returns (InterestRates memory) {
        uint256 borrowRate;
        uint256 supplyRate;
        if (utilization <= targetUtilization) {
            // Linear increase until the target utilization is reached
            borrowRate = baseBorrowRate + (utilization * rateSlope1) / 1e18;
        } else {
            // Linear increase at a steeper slope after reaching target utilization
            uint256 excessUtilization = utilization - targetUtilization;
            borrowRate = baseBorrowRate + (targetUtilization * rateSlope1) / 1e18 + (excessUtilization * rateSlope2) / 1e18;
        }
        uint256 feeAmount = (borrowRate * feeBps) / 1e18;
        supplyRate = (borrowRate - feeAmount) * utilization / 1e18;
        return InterestRates({
            utilization: utilization,
            supplyRate: supplyRate,
            borrowRate: borrowRate
        });
    }
}

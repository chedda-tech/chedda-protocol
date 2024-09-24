// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IInterestRateModel, InterestRates } from "./IInterestRateModel.sol";

contract DefaultInterestRateModel is IInterestRateModel {
    uint256 public baseBorrowRate;  // Initial interest rate
    uint256 public rateSlope1; // rate of increase when utilization <= targetUtilization
    uint256 public rateSlope2; // rate of increase when utilization > targetUtilization
    uint256 public targetUtilization; // Target utilization rate
    uint256 public reserveFactor;  // Protocol fee

    constructor(
        uint256 _baseBorrowRate,
        uint256 _rateSlope1,
        uint256 _rateSlope2,
        uint256 _targetUtilization,
        uint256 _reserveFactor
    ) {
        baseBorrowRate = _baseBorrowRate;
        rateSlope1 = _rateSlope1;
        rateSlope2 = _rateSlope2;
        targetUtilization = _targetUtilization;
        reserveFactor = _reserveFactor;
    }

    // Calculate the interest rate based on utilization
    function calculateInterestRates(uint256 utilization) public view returns (InterestRates memory) {
        uint256 borrowRate;
        uint256 supplyRate;
        uint256 effectiveSupplyRate;
        if (utilization <= targetUtilization) {
            // Linear increase until the target utilization is reached
            borrowRate = baseBorrowRate + (utilization * rateSlope1) / 1e18;
        } else {
            // Linear increase at a steeper slope after reaching target utilization
            uint256 excessUtilization = utilization - targetUtilization;
            borrowRate = baseBorrowRate + (targetUtilization * rateSlope1) / 1e18 + (excessUtilization * rateSlope2) / 1e18;
        }
        uint256 feeAmount = (borrowRate * reserveFactor) / 1e18;
        supplyRate = borrowRate * utilization / 1e18;
        effectiveSupplyRate = (borrowRate - feeAmount) * utilization / 1e18;
        return InterestRates({
            utilization: utilization,
            supplyRate: supplyRate,
            effectiveSupplyRate: effectiveSupplyRate,
            borrowRate: borrowRate
        });
    }
}

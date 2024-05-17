// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IInterestRatesModel, InterestRates } from "./IInterestRatesModel.sol";

contract BorrowSupplyRatesModel is IInterestRatesModel {
    uint256 public baseBorrowRate;  // Initial interest rate
    uint256 public steeperSlopeInterestRate; // Interest rate after reaching target utilization
    uint256 public targetUtilization; // Target utilization rate

    constructor(
        uint256 _baseBorrowRate,
        uint256 _steeperSlopeInterestRate,
        uint256 _targetUtilization
    ) {
        baseBorrowRate = _baseBorrowRate;
        steeperSlopeInterestRate = _steeperSlopeInterestRate;
        targetUtilization = _targetUtilization;
    }

    // Calculate the interest rate based on utilization
    function calculateInterestRates(uint256 utilization) public view returns (InterestRates memory) {
        uint256 supplyRate = 0;
        uint256 borrowRate = 0;
        if (utilization <= targetUtilization) {
            // Linear increase until the target utilization is reached
            borrowRate = baseBorrowRate + ((utilization * (steeperSlopeInterestRate - baseBorrowRate)) / targetUtilization);
        } else {
            // Linear increase at a steeper slope after reaching target utilization
            borrowRate = steeperSlopeInterestRate + (((utilization - targetUtilization) * (2 * steeperSlopeInterestRate - baseBorrowRate)) / (1e18 - targetUtilization));
        }
        supplyRate = borrowRate * utilization;
        return InterestRates({
            utilization: utilization,
            supplyRate: supplyRate,
            borrowRate: borrowRate
        });
    }
}

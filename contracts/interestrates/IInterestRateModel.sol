// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
/// @param utilization the current utilization rate.
/// @param supplyRate the interest rate earned by suppliers.
/// @param effectiveSupplyRate the interest rate earned by suppliers minus platform fees.
/// @param borrowRate the interest rate paid by borrowers.
struct InterestRates {
    uint256 utilization;
    uint256 supplyRate;
    uint256 effectiveSupplyRate;
    uint256 borrowRate;
}

/// @title IInterestRateModel 
/// @dev Interface representing interest rate model
interface IInterestRateModel {
    function calculateInterestRates(uint256 utilization) external view returns (InterestRates memory);
}

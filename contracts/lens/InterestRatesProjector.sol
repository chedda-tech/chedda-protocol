// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IInterestRatesModel, InterestRates} from "../pool/IInterestRatesModel.sol";

/// @title InterestRatesProjector
/// @notice Allows you to view the interest rates at various utilizations
contract InterestRatesProjector {

    /// @notice Returns the interest rates at various utilizations
    /// @param interestRatesModel The interest rate model
    /// @param utilizations An array of utilizations to return interest rates for. 1e18 = 100% utilization.
    /// @return interestRates An array of interest rates corresponding to utilizations passed in.
    function projection(address interestRatesModel, uint256[] calldata utilizations) external view returns (InterestRates[] memory) {
        IInterestRatesModel model = IInterestRatesModel(interestRatesModel);
        uint256 len = utilizations.length;
        InterestRates[] memory rates = new InterestRates[](len);
        for (uint256 i = 0; i < len; i++) {
            rates[i] =  model.calculateInterestRates(utilizations[i]);
        }
        return rates;
    }
}

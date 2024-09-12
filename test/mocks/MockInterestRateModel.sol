// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IInterestRateModel, InterestRates} from "../../contracts/interestrates/IInterestRateModel.sol";

contract MockInterestRateModel is IInterestRateModel {

    function calculateInterestRates(uint256 utilization) external pure returns (InterestRates memory) {
        return InterestRates({
            utilization: utilization,
            supplyRate: utilization/2,
            effectiveSupplyRate: utilization/3,
            borrowRate: utilization
        });
    }
}

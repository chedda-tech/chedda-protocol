// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IInterestRatesModel, InterestRates} from "../../contracts/pool/IInterestRatesModel.sol";

contract MockInterestRatesModel is IInterestRatesModel {

    function calculateInterestRates(uint256 utilization) external pure returns (InterestRates memory) {
        return InterestRates({
            utilization: utilization,
            supplyRate: utilization/2,
            borrowRate: utilization
        });
    }
}

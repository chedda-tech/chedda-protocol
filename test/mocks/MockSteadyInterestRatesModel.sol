// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IInterestRateModel, InterestRates } from "../../contracts/interestrates/IInterestRateModel.sol";
import {ud} from "prb-math/UD60x18.sol";

contract MockSteadyInterestRatesModel is IInterestRateModel {
    uint256 public borrowRate;
    uint256 public supplyRate;
    uint256 public reserveFactor;

    constructor(
        uint256 _borrowRate,
        uint256 _supplyRate,
        uint256 _reserveFactor
    ) {
        borrowRate = _borrowRate;
        supplyRate = _supplyRate;
        reserveFactor = _reserveFactor;
    }

    // Calculate the interest rate based on utilization
    function calculateInterestRates(uint256 utilization) public view returns (InterestRates memory) {
        uint256 effectiveSupplyRate = ud(supplyRate).mul(ud(1e18 - reserveFactor)).unwrap();
        return InterestRates({
            utilization: utilization,
            supplyRate: supplyRate,
            effectiveSupplyRate: effectiveSupplyRate,
            borrowRate: borrowRate
        });
    }
}

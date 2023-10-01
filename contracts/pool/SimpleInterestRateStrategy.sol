// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IInterestRateStrategy, InterestRates } from "./IInterestRateStrategy.sol";

contract SimpleInterestRateStrategy is Ownable, IInterestRateStrategy {

    uint256 public linearInterestRate;
    uint256 public exponentialInterestRate;
    uint256 public targetUtilization;

    constructor(uint256 _linearRate, uint256 _exponentialRate, uint256 _targetUtilization) {
        linearInterestRate = _linearRate;
        exponentialInterestRate = _exponentialRate;
        targetUtilization = _targetUtilization;
    }

    function getInterestRate(uint256 currentUtilization) public view returns (uint256) {
        if (currentUtilization < targetUtilization) {
            return linearInterestRate * currentUtilization / targetUtilization;
        } else {
            // Exponential increase after reaching the target utilization
            uint256 excessUtilization = currentUtilization - targetUtilization;
            uint256 exponentialIncrease = (exponentialInterestRate * excessUtilization * excessUtilization) / 100;
            return linearInterestRate + exponentialIncrease;
        }
    }

    function updateLinearInterestRate(uint256 newLinearRate) public onlyOwner {
        linearInterestRate = newLinearRate;
    }

    function updateExponentialInterestRate(uint256 newExponentialRate) public onlyOwner {
        exponentialInterestRate = newExponentialRate;
    }

    function updateTargetUtilization(uint256 newTargetUtilization) public onlyOwner {
        targetUtilization = newTargetUtilization;
    }

    function calculateInterestRates(
        uint256, // liquidityAdded,
        uint256//  liquidityTaken
    ) external pure returns (InterestRates memory) {
        InterestRates memory rates = InterestRates({
            supplyRate: 0.55e18,
            borrowRate: 0.75e18
        });
        return rates;
    }
}

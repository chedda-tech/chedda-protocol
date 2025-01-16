// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {IStakingPool} from "../../contracts/rewards/IStakingPool.sol";
import {IRewardsDistributor} from "../../contracts/rewards/IRewardsDistributor.sol";

contract MockRewardsDistributor is IRewardsDistributor {
    uint256 private _totalWeightSum;

    function sendRewards(address pool, uint256 amount) external {
        IStakingPool(pool).addRewards(amount);
    }
    
    function distribute() external pure returns (uint256) {
        return 0;
    }

    function totalWeightSum() external pure returns (uint256) {
        return 0;
    }

    function setTotalWeightSum(uint256 sum) external {
        _totalWeightSum = sum;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IStakingPool} from "../../contracts/rewards/IStakingPool.sol";
import {IRewardsDistributor} from "../../contracts/rewards/IRewardsDistributor.sol";

contract MockRewardsDistributor is IRewardsDistributor {
    function sendRewards(address pool, uint256 amount) external {
        IStakingPool(pool).addRewards(amount);
    }
}

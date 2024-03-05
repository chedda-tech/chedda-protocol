// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {ICheddaPool} from "../../contracts/rewards/ICheddaPool.sol";
import {ILockingGauge} from "../../contracts/rewards/ILockingGauge.sol";
import {IStakingPool} from "../../contracts/rewards/IStakingPool.sol";

contract MockCheddaPool is ICheddaPool {

    address private _gauge;
    address private _pool;

    function setGauge(address g) external {
        _gauge = g;
    }

    function setStakingPool(address p) external {
        _pool = p;
    }

    function gauge() external view returns (ILockingGauge) {
        return ILockingGauge(_gauge);
    }

    function stakingPool() external view returns (IStakingPool) {
        return IStakingPool(_pool);
    }

    function addRewards(uint256) external pure {
    }
}
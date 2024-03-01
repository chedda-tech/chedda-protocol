// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {ILockingGauge} from "./ILockingGauge.sol";
import {IStakingPool} from ".//IStakingPool.sol";

interface ICheddaPool {
    function gauge() external returns (ILockingGauge);
    function stakingPool() external returns (IStakingPool);
}

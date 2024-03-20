// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {ILockingGauge, LockTime, Lock} from "../../contracts/rewards/ILockingGauge.sol";

contract MockLockingGauge is ILockingGauge {
    event WeightSet(uint256 weight);

    uint256 private _weight;

    function setWeight(uint256 w) external {
        _weight = w;

        emit WeightSet(w);
    }

    function weight() external view returns (uint256) {
        return _weight;
    }
    
    function createLock(uint256, LockTime) external pure returns (uint256) {}

    function withdraw() external pure returns (uint256) {
        return 0;
    }

    function getLock(address) external pure returns (Lock memory) {
        return Lock({
            amount: 0,
            timeWeighted: 0,
            expiry: 0,
            rewardDebt: 0,
            lockTime: LockTime.ninetyDays
        });
    }

    function claim() external pure returns (uint256) {
        return 0;
    }

    function claimable(address) external pure returns (uint256) {
        return 0;
    }

    function addRewards(uint256) external pure {}
}

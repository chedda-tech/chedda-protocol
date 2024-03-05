// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRewardsDistributor} from "./IRewardsDistributor.sol";
import {ICheddaPool} from "./ICheddaPool.sol";
import {ILockingGauge} from "./ILockingGauge.sol";
import {IStakingPool} from "./IStakingPool.sol";

/// @title LockingGaugeRewardsDistributor
/// @notice Distributes token rewards to pools proportionally based on the pool's
/// `weight`.
contract LockingGaugeRewardsDistributor is Ownable, IRewardsDistributor {

    using SafeERC20 for IERC20;

    error AlreadyRegistered(address);
    error NotFound(address);

    event PoolRegistered(address indexed pool);
    event PoolUnregistered(address indexed pool);
    event RewardsDistributed(uint256 amount);

    IERC20 public token;

    ICheddaPool[] public pools;
    uint256 public stakingPortion = 0.6e18;
    uint256 public lockingPortion = 0.4e18;
    uint256 public constant Konstant = 1.0e18;

    constructor(address _token, address admin) Ownable(admin) {
        token = IERC20(_token);
    }

    /// @notice Registers a pool to receive rewards.
    /// @dev Can only be called by contract owner.
    /// @param _pool Address of the pool.
    function registerPool(ICheddaPool _pool) external onlyOwner() {
        uint256 poolsLength = pools.length;
        for (uint256 i = 0; i < poolsLength; i++) {
            if (pools[i] == _pool) {
                revert AlreadyRegistered(address(_pool));
            }
        }
        pools.push(_pool);

        emit PoolRegistered(address(_pool));
    }

    /// @notice Unregisters a pool.
    /// @param _pool Address of pool to unregister. Must have been previously registered.
    function unregisterPool(ICheddaPool _pool) external onlyOwner() {
        uint256 found = type(uint256).max;
        uint256 poolsLength = pools.length;
        for (uint256 i = 0; i < poolsLength; i++) {
            if (pools[i] == _pool) {
                found = i;
            }
        }
        if (found != type(uint256).max) {
            pools[found] = pools[poolsLength - 1];
            pools.pop();
            emit PoolUnregistered(address(_pool));
        } else {
            revert NotFound(address(_pool));
        }
    }

    /// @inheritdoc	IRewardsDistributor
    function distribute() external returns (uint256) {
        return _distribute();
    }

    /// @dev Internal reward distirbution function
    function _distribute() private returns (uint256) {
        uint256 length = pools.length;
        uint256 available = token.balanceOf(address(this));
        if (available == 0) {
            return 0;
        }
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < length; i++) {
            // get weights and total weight of pools
            ILockingGauge gauge = pools[i].gauge();
            totalWeight += gauge.weight();
        }

        for (uint256 i = 0; i < length; i++) {
            // -> distribute to pools based on weights.
            ILockingGauge gauge = pools[i].gauge();
            uint256 poolRewards = available * gauge.weight() / totalWeight;
            if (poolRewards > 0) {
                IStakingPool pool = pools[i].stakingPool();
                uint256 stakingRewards = poolRewards * stakingPortion / Konstant;
                token.safeIncreaseAllowance(address(pool), stakingRewards);
                pool.addRewards(stakingRewards);

                uint256 lockingRewards = poolRewards * lockingPortion / Konstant;
                token.safeIncreaseAllowance(address(gauge), lockingRewards);
                gauge.addRewards(lockingRewards);
            }
        }

        emit RewardsDistributed(available);

        return available;
    }
}

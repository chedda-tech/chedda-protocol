// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IAddressRegistry} from "../config/IAddressRegistry.sol";
import {ILendingPool} from "../pool/ILendingPool.sol";
import {ICheddaPool} from "../rewards/ICheddaPool.sol";
import {ILockingGauge} from "../rewards/ILockingGauge.sol";
import {IStakingPool} from "../rewards/IStakingPool.sol";
import {IPriceFeed} from "../oracle/IPriceFeed.sol";

/// @title AccountActor
/// @notice Provides views into accounts and positions.
contract AccountActor {

    /// @dev Emitted when the caller is not permitted to make a call.
    /// @param account The account making the call
    error NotAuthorized(address account);

    struct AccountSummary {
        uint256 netValue;
        uint256 supplied;
        uint256 borrowed;
        uint256 locked;
    }

    struct Position {
        address account;
        address pool;
        address asset;
        uint8 decimals;
        uint256 supplied;
        uint256 suppliedValue;
        uint256 borrowed;
        uint256 borrowedValue;
        uint256 debtValue;
        uint256 collateralValue;
        uint256 healthFactor;
        uint256 staked;
        uint256 lockRewardsClaimable;
        uint256 stakeRewardsClaimable;
        uint256 exposure; // used as flag to show in dashboard or not
    }

    IAddressRegistry public registry;

    constructor(address _registry) {
        registry = IAddressRegistry(_registry);
    }

    function accountSummary(address account) external pure returns (AccountSummary memory) {
        AccountSummary memory summary = AccountSummary({
            netValue: 0,
            supplied: 0,
            borrowed: 0,
            locked: 0
        });
        return summary;
    }

    /// @notice Checks amount of rewards that can be claimed by a given account.
    /// @param account The account to check
    /// @return tuple (stakeRewardsPending, lockRewardsPending). A tuple containing
    /// total amount of staking and lock rewards.
    /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    function claimableRewards(address account) external view returns (uint256, uint256) {
        address[] memory pools = registry.registeredPools();
        uint256 poolsLength = pools.length;
        uint256 stakeRewardsPending = 0;
        uint256 lockRewardsPending = 0;
        for (uint256 i = 0; i < poolsLength; i++) {
            ICheddaPool pool = ICheddaPool(pools[i]);
            IStakingPool stakingPool = IStakingPool(pool.stakingPool());
            ILockingGauge gauge = ILockingGauge(pool.gauge());
            stakeRewardsPending += stakingPool.claimable(account);
            lockRewardsPending += gauge.claimable(account);
        }
        
        return (stakeRewardsPending, lockRewardsPending);
    }

    /// @notice Claims all rewards an account has pending.
    /// @param account The account to claim rewards for.
    /// @return The total amount of rewards claimed.
    function claimAllRewards(address account) external returns (uint256) {
        if (msg.sender != account) {
            revert NotAuthorized(msg.sender);
        }
        address[] memory pools = registry.registeredPools();
        uint256 poolsLength = pools.length;
        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < poolsLength; i++) {
            ICheddaPool pool = ICheddaPool(pools[i]);
            IStakingPool stakingPool = IStakingPool(pool.stakingPool());
            ILockingGauge gauge = ILockingGauge(pool.gauge());

            // claim pool staking rewards
            uint256 amountToClaim = stakingPool.claimable(account);
            if (amountToClaim > 0) {
                totalClaimed += amountToClaim;
                stakingPool.claimFor(account);
            }

            // claim pool locking rewards
            amountToClaim = gauge.claimable(account);
            if (amountToClaim > 0) {
                totalClaimed += amountToClaim;
                gauge.claimFor(account);
            }
        }
        return totalClaimed;
    }

    /// @notice Returns an array containing tha accounts positions.
    /// @param account The account to check
    /// @param showActiveOnly If true only return positions in active pools, 
    /// else return positions in all registered pools.
    /// @return Array of accounts positions
    function allPositions(address account, bool showActiveOnly) external view returns (Position[] memory) {
        address[] memory pools;
        if (showActiveOnly) {
            pools = registry.activePools();
        } else {
            pools = registry.registeredPools();
        }
        uint256 poolsLength = pools.length;
        Position[] memory positions = new Position[](poolsLength);
        for (uint256 i = 0; i < poolsLength; i++) {
            positions[i] = getPosition(account, pools[i]);
        }
        return positions;
    }

    /// @notice Gets an account position in a lending pool.
    /// @param account The account to retrive the position for
    /// @param poolAddress The pool address
    /// @return The `Position` holding the values for the account position. 
    /// If `account` does not have a position in this pool the numerical values are all zero.
    function getPosition(address account, address poolAddress) public view returns (Position memory) {
        ILendingPool pool = ILendingPool(poolAddress);
        ERC20 poolAsset = pool.poolAsset();
        uint256 debtAmount = pool.debtToken().convertToAssets(pool.debtToken().balanceOf(account));
        Position memory position = Position({
            account: account,
            pool: poolAddress,
            asset: address(poolAsset),
            decimals: poolAsset.decimals(),
            supplied: pool.assetBalance(account),
            suppliedValue: 0,
            borrowed: debtAmount,
            borrowedValue: 0,
            debtValue: pool.getTokenMarketValue(address(poolAsset), debtAmount),
            collateralValue: pool.totalAccountCollateralValue(account),
            healthFactor: pool.accountHealth(account)
        });
        return position;
    }
}

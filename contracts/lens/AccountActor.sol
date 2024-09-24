// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IAddressRegistry} from "../config/IAddressRegistry.sol";
import {ILendingPool} from "../pool/ILendingPool.sol";
import {ICheddaPool} from "../rewards/ICheddaPool.sol";
import {ILockingGauge} from "../rewards/ILockingGauge.sol";
import {IStakingPool} from "../rewards/IStakingPool.sol";
import {IPriceFeed} from "../oracle/IPriceFeed.sol";
import {UD60x18, ud} from "prb-math/UD60x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {MathLib} from "../library/MathLib.sol";

/// @title AccountActor
/// @notice Provides views into accounts and positions.
contract AccountActor {
    /// @dev Emitted when the caller is not permitted to make a call.
    /// @param account The account making the call
    error NotAuthorized(address account);

    struct AccountSummary {
        uint256 netValue;
        uint256 suppliedValue;
        uint256 borrowedValue;
        uint256 lockedValue;
    }

    /// @notice Contains info about a position.
    struct Position {
        address account;
        address pool;
        address asset;
        uint8 decimals;
        uint256 supplied;
        uint256 borrowed;
        uint256 suppliedValue;
        uint256 borrowedValue;
        uint256 collateralValue;
        uint256 healthFactor;
        uint256 staked;
        uint256 locked;
        uint256 stakeRewardsClaimable;
        uint256 lockRewardsClaimable;
        uint256 exposure; // used as flag to show in dashboard or not
    }

    using MathLib for uint256;
    using SafeCast for int256;

    /// @notice Chedda address registry
    IAddressRegistry public registry;

    /// @dev Constructor
    /// @param _registry The address registry address.
    constructor(address _registry) {
        registry = IAddressRegistry(_registry);
    }

    /// @notice Returns the account status summed up.
    /// @param account The account to return stats for.
    /// @return the `AccountSummary` object containing account stats.
    function accountSummary(
        address account
    ) external view returns (AccountSummary memory) {
        address[] memory pools = registry.registeredPools();
        uint256 totalSuppliedValue;
        uint256 totalBorrowedValue;
        uint256 totalLockedValue;

        for (uint256 i = 0; i < pools.length; i++) {
            ILendingPool pool = ILendingPool(pools[i]);
            uint8 assetDecimals = pool.poolAsset().decimals();
            uint256 normalizedAssetPrice = pool
                .priceFeed()
                .readPrice(address(pool.poolAsset()), 0)
                .toUint256()
                .normalized(pool.priceFeed().decimals(), 18);
            uint256 supplied = pool.assetBalance(account);
            uint256 borrowed = pool.debtToken().convertToAssets(
                pool.debtToken().balanceOf(account)
            );
            totalSuppliedValue += ud(supplied.normalized(assetDecimals, 18))
                .mul(ud(normalizedAssetPrice))
                .unwrap();
            totalBorrowedValue += ud(borrowed.normalized(assetDecimals, 18))
                .mul(ud(normalizedAssetPrice))
                .unwrap();
            totalLockedValue += _getCheddaTokenValue(
                ICheddaPool(pools[i]).gauge().getLock(account).amount
            );
        }

        return
            AccountSummary({
                netValue: totalSuppliedValue > totalBorrowedValue
                    ? totalSuppliedValue - totalBorrowedValue
                    : 0,
                suppliedValue: totalSuppliedValue,
                borrowedValue: totalBorrowedValue,
                lockedValue: totalLockedValue
            });
    }

    function _getCheddaTokenValue(
        uint256 amount
    ) private view returns (uint256) {
        IPriceFeed cheddaPriceFeed = IPriceFeed(registry.cheddaPriceOracle());
        uint256 normalizedCheddaPrice = cheddaPriceFeed
            .readPrice(registry.cheddaToken(), 0)
            .toUint256()
            .normalized(cheddaPriceFeed.decimals(), 18);
        // NOTE: assumes 18 decimals on amount. Safe assumption since only used for Chedda token
        return ud(amount).mul(ud(normalizedCheddaPrice)).unwrap();
    }

    /// @notice Checks amount of rewards that can be claimed by a given account.
    /// @param account The account to check
    /// @return tuple (stakeRewardsPending, lockRewardsPending). A tuple containing
    /// total amount of staking and lock rewards.
    function allClaimableRewards(
        address account
    ) external view returns (uint256, uint256) {
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
                totalClaimed += stakingPool.claimFor(account);
            }

            // claim pool locking rewards
            amountToClaim = gauge.claimable(account);
            if (amountToClaim > 0) {
                totalClaimed += gauge.claimFor(account);
            }
        }
        return totalClaimed;
    }

    /// @notice Returns an array containing tha accounts positions.
    /// @param account The account to check
    /// @param showActiveOnly If true only return positions in active pools,
    /// else return positions in all registered pools.
    /// @return Array of accounts positions
    function allPositions(
        address account,
        bool showActiveOnly
    ) external view returns (Position[] memory) {
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
    function getPosition(
        address account,
        address poolAddress
    ) public view returns (Position memory) {
        ILendingPool pool = ILendingPool(poolAddress);
        IPriceFeed priceFeed = pool.priceFeed();
        uint8 assetDecimals = pool.poolAsset().decimals();
        uint256 supplied = pool.assetBalance(account);
        uint256 borrowed = pool.debtToken().convertToAssets(
            pool.debtToken().balanceOf(account)
        );
        uint256 normalizedAssetPrice = priceFeed
            .readPrice(address(pool.poolAsset()), 0)
            .toUint256()
            .normalized(priceFeed.decimals(), 18);
        IStakingPool stakingPool = ICheddaPool(poolAddress).stakingPool();
        ILockingGauge gauge = ICheddaPool(poolAddress).gauge();
        // can't declare additioal variables due to stack too deep.
        Position memory position = Position({
            account: account,
            pool: poolAddress,
            asset: address(pool.poolAsset()),
            decimals: assetDecimals,
            supplied: supplied,
            borrowed: borrowed,
            suppliedValue: ud(supplied.normalized(assetDecimals, 18))
                .mul(ud(normalizedAssetPrice))
                .unwrap(),
            borrowedValue: ud(borrowed.normalized(assetDecimals, 18))
                .mul(ud(normalizedAssetPrice))
                .unwrap(),
            collateralValue: pool.totalAccountCollateralValue(account),
            healthFactor: pool.accountHealth(account),
            staked: stakingPool.stakingBalance(account),
            locked: gauge.getLock(account).amount,
            stakeRewardsClaimable: stakingPool.claimable(account),
            lockRewardsClaimable: gauge.claimable(account),
            exposure: _getExposure(account, poolAddress)
        });
        return position;
    }

    /// @dev returns a non zero value if an account has some exposure to a given pool.
    /// Exposure is any off supplied, borrowed, staked, locked, claimable rewards in a pool.
    function _getExposure(
        address account,
        address poolAddress
    ) private view returns (uint256) {
        ILendingPool pool = ILendingPool(poolAddress);
        IStakingPool stakingPool = ICheddaPool(poolAddress).stakingPool();
        ILockingGauge gauge = ICheddaPool(poolAddress).gauge();

        uint256 hasSupplied = pool.assetBalance(account);
        uint256 hasborrowed = pool.debtToken().balanceOf(account);
        uint256 staked = stakingPool.stakingBalance(account);
        uint256 locked = gauge.getLock(account).amount;
        uint256 stakeRewards = stakingPool.claimable(account);
        uint256 lockRewards = gauge.claimable(account);
        return
            hasSupplied +
            hasborrowed +
            staked +
            locked +
            stakeRewards +
            lockRewards;
    }
}

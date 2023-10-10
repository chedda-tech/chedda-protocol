// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import { ILendingPool } from "../pool/ILendingPool.sol";
import { IPriceFeed } from "../oracle/IPriceFeed.sol";

contract LendingPoolLens is Ownable {

    struct LendingPoolStats {
        string characterization;
        uint256 supplied;
        uint256 suppliedValue;
        uint256 borrowed;
        uint256 borrowedValue;
        uint256 baseSupplyAPY;
        uint256 maxSupplyAPY;
        uint256 baseBorrowAPY;
        uint256 maxBorrowAPY;
        uint256 utilization;
        uint256 feesPaid;
        address[] collaterals;
    }

    struct AggregateStats {
        uint256 totalSuppliedValue;
        uint256 totalBorrowedValue;
        uint256 totalAvailableValue;
        uint256 totalFeesPaid;
        uint256 numberOfVaults;
        uint256 tvl;
    }

    struct LendingPoolCollateralInfo {
        address collateral;
        uint256 amountDeposited;
        uint256 depositCap;
    }

    struct LendingPoolAccountInfo {
        uint256 totalSupplied;
        uint256 totalBorrowed;
        uint256 healthFactor;
    }

    struct LendingPoolInfo {
        uint256 assetOraclePrice;
        uint256 interestFeePercentage;
        uint256 liquidationThreshold;
        uint256 liquidationPenalty;
    }

    event PoolRegistered(address indexed pool, address indexed caller);
    event PoolUnregistered(address indexed pool, address indexed caller);

    using SafeCast for int256;

    address[] private _pools;

    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) Ownable(_owner) {}

    ///////////////////////////////////////////////////////////////////////////
    ///                 Registration/Unregistration
    ///////////////////////////////////////////////////////////////////////////
    function registerLendingPool(address pool) external onlyOwner() returns (bool) {
        if (_poolAlreadyRegistered(pool)) {
            return false;
        }
        _pools.push(pool);

        emit PoolRegistered(pool, msg.sender);
        return true;
    }

    function unregisterLendingPool(address pool) external onlyOwner() returns (bool) {
        uint256 foundIndex = type(uint256).max;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i] == pool) {
                foundIndex = i;
            }
        }
        if (foundIndex != type(uint256).max) {
            _pools[foundIndex] = _pools[_pools.length - 1];
            _pools.pop();

            emit PoolUnregistered(pool, msg.sender);
            return true;
        }
        return false;
    }

    function _poolAlreadyRegistered(address pool) private view returns (bool) {
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i] == pool) {
                return true;
            }
        }
        return false;
    }

    function lendingPools() external view returns (address[] memory pools) {
        pools = _pools;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     Aggregate stats
    ///////////////////////////////////////////////////////////////////////////
    function getAggregateStats() external view returns (AggregateStats memory) {
        uint256 totalSuppliedValue = 0;
        uint256 totalBorrowedValue = 0;
        uint256 totalAvailableValue = 0;
        uint256 totalFeesPaid = 0;
        uint256 tvl = 0;
        ILendingPool pool;
        IPriceFeed priceFeed;

        for (uint256 i = 0; i < _pools.length; i++) {
            pool = ILendingPool(_pools[i]);
            priceFeed = pool.priceFeed();
            UD60x18 assetPrice = ud(priceFeed.readPrice(address(pool.poolAsset()), 0).toUint256());
            totalSuppliedValue += ud(pool.supplied()).mul(assetPrice).unwrap();
            totalBorrowedValue += ud(pool.borrowed()).mul(assetPrice).unwrap();
            totalAvailableValue += ud(pool.available()).mul(assetPrice).unwrap();
            totalFeesPaid += pool.feesPaid();
            tvl += pool.tvl();
        }
        AggregateStats memory stats = AggregateStats({
            totalSuppliedValue: totalSuppliedValue,
            totalBorrowedValue: totalBorrowedValue,
            totalAvailableValue: totalAvailableValue,
            totalFeesPaid: totalFeesPaid,
            numberOfVaults: _pools.length,
            tvl: tvl
        });
        return stats;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     Stats for one pool
    ///////////////////////////////////////////////////////////////////////////
    function getLendingPoolStats(address poolAddress) external view returns (LendingPoolStats memory) {
        ILendingPool pool = ILendingPool(poolAddress);
        uint256 supplied = pool.supplied();
        uint256 borrowed = pool.borrowed();
        uint256 assetPrice = pool.priceFeed().readPrice(address(pool.poolAsset()), 0).toUint256();

        LendingPoolStats memory stats = LendingPoolStats({
            characterization: pool.characterization(),
            supplied: pool.supplied(),
            borrowed: pool.borrowed(),
            suppliedValue: ud(supplied).mul(ud(assetPrice)).unwrap(),
            borrowedValue: ud(borrowed).mul(ud(assetPrice)).unwrap(),
            baseSupplyAPY: pool.baseSupplyAPY(),
            baseBorrowAPY: pool.baseBorrowAPY(),
            maxSupplyAPY: pool.baseSupplyAPY(), // TODO: base + reward rate from gauge
            maxBorrowAPY: pool.baseBorrowAPY(), // same here
            utilization: pool.utilization(),
            feesPaid: 0,
            collaterals: pool.collaterals()
        });
        return stats;
    }
}

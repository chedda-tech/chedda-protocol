// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ILendingPool } from "../pool/ILendingPool.sol";
import { IPriceFeed } from "../oracle/IPriceFeed.sol";
import { MathLib } from "../library/MathLib.sol";

/// @title LendingPoolLens
/// @notice Provides utility functions to view the state of LendingPools
contract LendingPoolLens is Ownable {

    struct PoolStats {
        address pool;
        address asset;
        uint8 decimals;
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
        uint256 tvl;
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

    struct PoolCollateralInfo {
        address collateral;
        uint8 decimals;
        uint256 amountDeposited;
        uint256 value;
        uint256 collateralFactor;
    }

    struct LendingPoolInfo {
        uint256 assetOraclePrice;
        uint256 interestFeePercentage;
        uint256 liquidationThreshold;
        uint256 liquidationPenalty;
    }

    struct AccountCollateralDeposited {
        address token;
        uint8 decimals;
        uint256 amount;
        uint256 value;
        uint256[] tokenIds;
    }

    struct AccountInfo {
        uint256 supplied;
        uint256 borrowed;
        uint8 decimals;
        uint256 healthFactor;
        uint256 totalCollateralValue;
        AccountCollateralDeposited[] collateralDeposited;
    }

    event PoolRegistered(address indexed pool, address indexed caller);
    event PoolUnregistered(address indexed pool, address indexed caller);

    error AlreadyRegistered(address pool);
    error NotRegistered(address pool);

    using SafeCast for int256;
    using MathLib for uint256;

    address[] private _pools;
    mapping (address => bool) private _activePools;

    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) Ownable(_owner) {}

    ///////////////////////////////////////////////////////////////////////////
    ///                 Registration/Unregistration
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Registers a new lending pool
    /// @dev Can only be called by owner
    /// Reverts if pools is already registered.
    /// Emits PoolRegistered(address pool, address caller)
    /// @param pool The address of pool.
    /// @param isActive The active state of pool used for filtering.
    function registerPool(address pool, bool isActive) external onlyOwner() {
        if (_poolAlreadyRegistered(pool)) {
            revert AlreadyRegistered(pool);
        }
        _pools.push(pool);
        _activePools[pool] = isActive;

        emit PoolRegistered(pool, msg.sender);
    }

    /// @notice Unregisters a lending pool
    /// @dev Can only be called by admin. Reverts if pool is not registered
    /// Emits PoolRegistered(address pool, address caller)
    /// @param pool The pool to register
    function unregisterPool(address pool) external onlyOwner() {
        if (!_poolAlreadyRegistered(pool)) {
            revert NotRegistered(pool);
        }
        uint256 foundIndex = type(uint256).max;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i] == pool) {
                foundIndex = i;
            }
        }
        if (foundIndex != type(uint256).max) {
            _pools[foundIndex] = _pools[_pools.length - 1];
            _pools.pop();
            _activePools[pool] = false;

            emit PoolUnregistered(pool, msg.sender);
        }
    }

    /// @notice Sets a pool as active
    /// @dev Pools can be filtered by their active state
    /// @param pool The pool to set active or inactive
    /// @param isActive boolean flag to set pool as active or not
    function setActive(address pool, bool isActive) external onlyOwner() {
        if (!_poolAlreadyRegistered(pool)) {
            revert NotRegistered(pool);
        }
        _activePools[pool] = isActive;
    }

    /// @dev checks if a pool is already registered
    function _poolAlreadyRegistered(address pool) private view returns (bool) {
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i] == pool) {
                return true;
            }
        }
        return false;
    }

    /// @notice Returns a list of all the registered pools
    /// @return pools The addresses of all registered pools
    function registeredPools() external view returns (address[] memory) {
        return _pools;
    }

    /// @notice Returns a list of all the active pools
    /// @return pools The addresses of all active pools
    function activePools() external view returns (address[] memory) {
        uint256 numberActive = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_activePools[_pools[i]]) {
                numberActive += 1;
            }
        }
        if (numberActive == 0) {
            return new address[](0);
        }
        address[] memory pools = new address[](numberActive);
        uint256 j = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_activePools[_pools[i]]) {
                pools[j++] = _pools[i];
            }
        }
        return pools;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                     Aggregate stats
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @return aggregateStats The aggregated stats of the all registred pools
    function getAggregateStats() external view returns (AggregateStats memory) {
        uint256 totalSuppliedValue = 0;
        uint256 totalBorrowedValue = 0;
        uint256 totalAvailableValue = 0;
        uint256 totalFeesPaid = 0;
        uint256 tvl = 0;
        uint8 assetDecimals;
        ILendingPool pool;
        IPriceFeed priceFeed;

        for (uint256 i = 0; i < _pools.length; i++) {
            pool = ILendingPool(_pools[i]);
            priceFeed = pool.priceFeed();
            assetDecimals = pool.poolAsset().decimals();
            UD60x18 assetPrice = ud(priceFeed.readPrice(address(pool.poolAsset()), 0).toUint256().normalized(priceFeed.decimals(), 18));
            totalSuppliedValue += ud(pool.supplied().normalized(assetDecimals, 18)).mul(assetPrice).unwrap();
            totalBorrowedValue += ud(pool.borrowed().normalized(assetDecimals, 18)).mul(assetPrice).unwrap();
            totalAvailableValue += ud(pool.available().normalized(assetDecimals, 18)).mul(assetPrice).unwrap();
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

    /// @notice Returns various metrics of specified pools.
    /// @dev Returns an array of `PoolStats` objects.
    /// Reverts with NotRegistered(pool) error if a pool in the list is not registered.
    /// @param pools The list of pools to return stats for.
    /// @return poolStats An array of `PoolStats` objects, containing the stats for specified pools.
    function getPoolStatsList(address[] memory pools) external view returns (PoolStats[] memory) {
        for (uint256 i = 0; i < pools.length; i++) {
            if (!_poolAlreadyRegistered(pools[i])) {
                revert NotRegistered(pools[i]);
            }
        }
        PoolStats[] memory statsList = new PoolStats[](pools.length);
        PoolStats memory stats;
        for (uint256 i = 0; i < pools.length; i++) {
            stats = getPoolStats(pools[i]);
            statsList[i] = stats;
        }
        return statsList;
    }

    /// @notice Regturns the metrics of a specified pool.
    /// @dev Reverts with `NotRegistered(address) error if the pool address is not registered.
    /// @param poolAddress The address of the pool to return stats for
    /// @return poolStats The `PoolStats` object containing the stats for specified pool.
    function getPoolStats(address poolAddress) public view returns (PoolStats memory) {
        if (!_poolAlreadyRegistered(poolAddress)) {
            revert NotRegistered(poolAddress);
        }
        ILendingPool pool = ILendingPool(poolAddress);
        uint256 supplied = pool.supplied();
        uint256 borrowed = pool.borrowed();
        uint8 assetDecimals = pool.poolAsset().decimals();
        IPriceFeed priceFeed = pool.priceFeed();
        uint256 normalizedAssetPrice = priceFeed.readPrice(address(pool.poolAsset()), 0).toUint256()
            .normalized(priceFeed.decimals(), 18);

        PoolStats memory stats = PoolStats({
            pool: address(this),
            asset: address(pool.poolAsset()),
            decimals: assetDecimals,
            characterization: pool.characterization(),
            supplied: supplied,
            borrowed: borrowed,
            suppliedValue: ud(supplied.normalized(assetDecimals, 18)).mul(ud(normalizedAssetPrice)).unwrap(),
            borrowedValue: ud(borrowed.normalized(assetDecimals, 18)).mul(ud(normalizedAssetPrice)).unwrap(),
            baseSupplyAPY: pool.baseSupplyAPY(),
            baseBorrowAPY: pool.baseBorrowAPY(),
            maxSupplyAPY: pool.baseSupplyAPY(), // TODO: base + reward rate from gauge
            maxBorrowAPY: pool.baseBorrowAPY(), // same here
            utilization: pool.utilization(),
            feesPaid: pool.feesPaid(),
            tvl: pool.tvl(),
            collaterals: pool.collaterals()
        });
        return stats;
    }

    /// @notice Returns information about a given account in a specified pool. 
    /// @param poolAddress The pool to return account info for.
    /// @param account The account to return info about.
    /// @return info An `AccountInfo` obect about `account` position in the pool.
    function getPoolAccountInfo(address poolAddress, address account) external view returns (AccountInfo memory) {
        ILendingPool pool = ILendingPool(poolAddress);
        uint256 supplied = pool.assetBalance(account);
        uint256 borrowed = pool.debtToken().convertToAssets(pool.debtToken().balanceOf(account));
        uint256 healthFactor = pool.accountHealth(account);
        uint256 collateralValue = pool.totalAccountCollateralValue(account);
        address[] memory collaterals = pool.collaterals();
        AccountCollateralDeposited[] memory collateralDeposited = new AccountCollateralDeposited[](collaterals.length);
        address collateral;
        for (uint256 i = 0; i < collaterals.length; i++) {
            collateral = collaterals[i];
            uint8 collateralDecimals = ERC20(collateral).decimals();
            uint256 collateralAmount = pool.accountCollateralAmount(account, collateral);
            AccountCollateralDeposited memory deposited = AccountCollateralDeposited({
                token: collateral,
                decimals: collateralDecimals,
                amount: collateralAmount,
                value: pool.getTokenCollateralValue(collateral, collateralAmount),
                tokenIds: new uint256[](0)
            });
            collateralDeposited[i] = deposited;
        }
        AccountInfo memory accountInfo = AccountInfo({
            supplied: supplied,
            borrowed: borrowed,
            decimals: ERC20(pool.poolAsset()).decimals(),
            healthFactor: healthFactor,
            totalCollateralValue: collateralValue,
            collateralDeposited: collateralDeposited
        });
        return accountInfo;
    }

    /// @notice Returns information about colalteral in the pool
    /// @param poolAddress The pool to return collateral info for.
    /// @return info The `PoolCollateralInfo` about collateral in the specified pool.
    function getPoolCollateral(address poolAddress) external view returns (PoolCollateralInfo[] memory) {
        ILendingPool pool = ILendingPool(poolAddress);
        address[] memory collaterals = pool.collaterals();
        address collateral;
        PoolCollateralInfo[] memory infoList = new PoolCollateralInfo[](collaterals.length);
        for (uint256 i = 0; i < collaterals.length; i++) {
            collateral = collaterals[i];
            uint256 collateralAmount = pool.tokenCollateralDeposited(collateral);
            infoList[i] = PoolCollateralInfo({
                collateral: collateral,
                decimals: ERC20(collateral).decimals(),
                amountDeposited: collateralAmount,
                value: pool.getTokenCollateralValue(collateral, collateralAmount),
                collateralFactor: pool.collateralFactor(collateral)
            });
        }
        return infoList;
    }
}

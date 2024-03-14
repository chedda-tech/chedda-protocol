// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IAddressRegistry} from "../config/IAddressRegistry.sol";
import {ILendingPool} from "../pool/ILendingPool.sol";
import {IPriceFeed} from "../oracle/IPriceFeed.sol";

/// @title AccountLens
/// @notice Provides views into accounts and positions.
contract AccountLens {

    struct Position {
        address account;
        address pool;
        address asset;
        uint8 decimals;
        uint256 supplied;
        uint256 borrowed;
        uint256 debtValue;
        uint256 collateralValue;
        uint256 healthFactor;
    }

    IAddressRegistry public registry;

    constructor(address _registry) {
        registry = IAddressRegistry(_registry);
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
            borrowed: debtAmount,
            debtValue: pool.getTokenMarketValue(address(poolAsset), debtAmount),
            collateralValue: pool.totalAccountCollateralValue(account),
            healthFactor: pool.accountHealth(account)
        });
        return position;
    }
}

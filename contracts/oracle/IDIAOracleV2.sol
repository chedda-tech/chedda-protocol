// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev DIA oracle interface
interface IDIAOracleV2 {

    /// @notice Returns the price and last update time of a given price feed.
    /// @param key The key to get price for. e.g BTCUSD
    /// @return lastPrice last price reported
    /// @return lastUpdated Timestamp of last update
    function getValue(string memory key) external view returns (uint128 lastPrice, uint128 lastUpdated);
}
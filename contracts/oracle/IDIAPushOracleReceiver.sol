// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

struct ResponseData {
    string key;
    uint128 timestamp;
    uint128 data;
}

/// @dev DIA oracle interface
interface IDIAPushOracleReceiver {

    /// @notice Returns the price and last update time of a given price feed.
    /// @param key The key to get price for. e.g BTCUSD
    /// @return data The price data.
    function updates(string memory key) external view returns (ResponseData memory data);
}

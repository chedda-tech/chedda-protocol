// SPDX-License-Identifier: BUSL-1.3
pragma solidity 0.8.27;

import { IPriceFeed } from "./IPriceFeed.sol";
import {IDIAOracleV2} from "./IDIAOracleV2.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title DIAPriceFeed
/// @notice Represents an instance of a feed that reads values from a DIA oracle.
contract DIAPriceFeed is IPriceFeed {

    using SafeCast for uint128;
    using SafeCast for uint256;

    /// @dev oracle address
    address public oracle;

    /// @dev number of decimals for values returned by this feed.
    uint8 public decimals;

    /// @dev mapping from token address to key used to fetch prices from DIA oracle.
    mapping(address => string) public feedKeyMap;

    /// @notice Explain to an end user what this does
    /// @param key The DIA feed key. E.g ETH/USD
    /// @param tokenAddress The address of asset.
    struct FeedKeyMap {
        string key;
        address tokenAddress;
    }
    
    /// @notice Constructor
    /// @param _oracle The oracle address.
    /// @param _decimals The number of decimals for values returned from `readPrice`.
    /// @param _initFeedMap A map of token address to feed key.
    constructor(address _oracle, uint8 _decimals, FeedKeyMap[] memory _initFeedMap) {
        oracle = _oracle;
        decimals = _decimals;
        uint256 len = _initFeedMap.length;
        for (uint256 i = 0; i < len; i++) {
            feedKeyMap[_initFeedMap[i].tokenAddress] = _initFeedMap[i].key;
        }
    }

    /// @notice Get latest price of asset.
    /// @param token address of the asset's token.
    /// @return price the price of the asset
    function readPrice(address token) external view returns (int256 price, uint256 lastUpdated) {
        string memory key = feedKeyMap[token];
        (uint128 price128, uint128 updated) = IDIAOracleV2(oracle).getValue(key);
        return (price128.toInt256(), uint256(updated));
    }
}

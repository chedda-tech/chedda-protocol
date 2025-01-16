// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

interface IPriceFeed {
    /// @dev The decimals of values returned by this feed.
    function decimals() external view returns (uint8);

    /// @notice Get latest price of asset. For ERC-20 tokens, `tokenID` parameter is unused.
    /// tokenID parameter is for forwards compatibility.
    /// @param token address of the asset's token.
    /// @return price the price of the asset
    function readPrice(address token) external view returns (int256 price, uint256 lastUpdated);
}

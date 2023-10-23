// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface IPriceFeed {
    /// @dev The decimals of values returned by this feed.
    function decimals() external view returns (uint8);

    /// @notice The token this feed returns a price for.
    /// @return address token addrss.
    function token() external view returns (address);

    /// @notice Get latest price of asset. For ERC-20 tokens, `tokenID` parameter is unused.
    /// tokenID parameter is for forwards compatibility.
    /// @param token address of the asset's token.
    /// @param tokenID The number of tokens
    /// @return price the price of the asset
    function readPrice(address token, uint256 tokenID) external view returns (int price);
}

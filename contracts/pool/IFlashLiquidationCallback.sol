// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

/// @title IFlashLiquidationCallback 
/// @notice Interface specifying flash liquidation callback contract.
interface IFlashLiquidationCallback {

    /// @notice Function to be executed during a flash liquidation.
    /// @dev This function is called by the lending pool. This contains any logic
    /// such as swap liquidated collateral tokens for asset tokens and return asset tokens
    /// to pool.
    /// @param data encoded data parameter containing all information required by the function call.
    function execute(bytes calldata data) external;
}

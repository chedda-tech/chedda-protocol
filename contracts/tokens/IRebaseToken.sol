// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title IRebaseToken
/// @notice Interface representing a rebase token
interface IRebaseToken {
    /// @notice Called to perform a rebase on the token
    function rebase() external returns (uint256);
}

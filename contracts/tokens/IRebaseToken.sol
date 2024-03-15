// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IRebaseToken
/// @notice Interface representing a rebase token
interface IRebaseToken is IERC20 {
    /// @notice Called to perform a rebase on the token
    function rebase() external returns (uint256);
}

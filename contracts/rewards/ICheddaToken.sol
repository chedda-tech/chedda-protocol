// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ICheddaToken
/// @notice Interface representing a rebase token
interface ICheddaToken is IERC20 {
    /// @notice Called to perform a rebase on the token
    function rebase() external returns (uint256);

    function emissionPerSecond() external view returns (uint256);
}

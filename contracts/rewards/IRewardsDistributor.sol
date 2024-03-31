// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title IRewardsDistributor
/// @notice Interface implmented to distribute rewards. Rewards are distributed based on internal logic
/// thus, it's up to the implementation to define the reward distribution strategy.
interface IRewardsDistributor {
    /// @notice Distributes rewwards to registered pools based on internal logic.
    /// @return The amount of token distributed.
    function distribute() external returns (uint256);

    /// @notice Returns the total weight of all the pools.
    /// @return The total weight of all registered pools.
    function totalWeightSum() external returns (uint256);
}

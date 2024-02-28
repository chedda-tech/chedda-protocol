// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface IStakingPool {
    /// @notice Stakes tokens to earn rewards.
    /// @dev Unstaking claims any pending rewards.
    /// @param amount The amount to unstake.
    /// @return The amount of rewards claimed.
    function stake(uint256 amount) external returns (uint256);

    /// @notice Unstakes previously staked tokens
    /// @dev Unstaking claims any pending rewards.
    /// @param amount The amount to unstake.
    /// @return The amount of rewards claimed
    function unstake(uint256 amount) external returns (uint256);

    /// @notice Claim any pending rewards.
    /// @dev Emits `RewardsClaimed(address, uint)` event.
    /// @return The amount claimed.
    function claim() external returns (uint256);

    /// @notice Returns pending rewards for given account.
    /// @param account The account to get the pending rewards for.
    /// @return The amount of rewards that can currently be claimed by this account
    function claimable(address account) external view returns (uint256);

    /// @notice Returns the staking balance of a given account.
    /// @param account The account to return staking balance for.
    /// @return The amount staked by account
    function stakingBalance(address account) external view returns (uint256);

    /// @notice Adds rewards to the pool
    /// @dev Can only be called by the rewarder set in the `AddressRegistry`.
    /// Caller must have previously approved this contract to `transferFrom` amount.
    ///     emits `RewardsAdded(uint amount)` event.
    /// @param amount The amount of rewards to add.
    function addRewards(uint256 amount) external;
}

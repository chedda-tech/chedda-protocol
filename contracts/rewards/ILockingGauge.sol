// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @notice Enum representing the possible lock times
enum LockTime {
    thirtyDays,
    ninetyDays,
    oneEightyDays,
    threeSixtyDays
}

/// @notice The structure that represents an active lock.
struct Lock {
    uint256 amount;
    uint256 timeWeighted;
    uint256 expiry;
    uint256 rewardDebt;
    LockTime lockTime;
}

    
interface ILockingGauge {
    
    /// @notice Returns the total amount of time weighted locked tokens.
    /// @return The time weighted locked tokens.
    function weight() external view returns (uint256);
    
    /// @notice Locks CHEDDA token for the given lock time.
    /// @dev Explain to a developer any extra details
    /// @param amount The token amount to lock
    /// @param time The lock time. This is specified by the `LockTime` enum.
    /// @return The expiry of the created lock
    function createLock(uint256 amount, LockTime time) external returns (uint256);

    /// @notice Withdraws locked CHEDDA after the lock expires
    /// @dev A lock must exist and must have already expired for this call to succeed.
    /// @return The amount of CHEDDA withdrawn. This is equal to the total amount of 
    /// CHEDDA previously locked by the caller.
    function withdraw() external returns (uint256);

    /// @notice Returns the `Lock` struct for the given account if it exists.
    /// @param account THe account to return the lock for.
    /// @return The lock info.
    function getLock(address account) external view returns (Lock memory);

    /// @notice Claims any pending rewards
    /// @dev Rewards are available if a lock exists and rewards have been distributed
    /// to this locking pool. 
    /// @return The amount of reward tokens received.
    function claim() external returns (uint256);

    /// @notice Returns the accrued token reward amount that can currently be claimed  by a given account.
    /// @param account The account to return reward amount for.
    /// @return The amount of claimable rewards.
    function claimable(address account) external view returns (uint256);

    /// @notice Adds token rewards to this pool
    /// @param amount The amount to add.
    function addRewards(uint256 amount) external;
}

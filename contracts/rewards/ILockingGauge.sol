// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import {ICheddaToken} from "../tokens/ICheddaToken.sol";

/// @notice Enum representing the possible lock times
enum LockTime {
    zero,
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

    /// @notice The token locked to this gauge.
    /// @return The token address.
    function token() external view returns (ICheddaToken);
    
    /// @notice Returns the total amount of time weighted locked tokens.
    /// @return The time weighted locked tokens.
    function totalWeight() external view returns (uint256);
    
    /// @notice Locks CHEDDA token for the given lock time.
    /// @param amount The token amount to lock
    /// @param time The lock time. This is specified by the `LockTime` enum.
    /// @return The expiry of the created lock
    function createLock(uint256 amount, LockTime time) external returns (uint256);

    /// @notice Extends an existing lock.
    /// @dev A lock owned by the caller must already exist.
    /// is the current time + length of lock based on lock time.
    /// @param time The new time for the lock.
    /// @return The new expiry for the lock
    function extendLock(LockTime time) external returns (uint256);

    /// @notice Adds more CHEDDA to an existing lock. This does not change the lock expiry.
    /// @dev A lock owned by the caller must already exist.
    /// @param amount The amount of CHEDDA to add to the lock.
    /// @return The total amoun tlocked by the user.
    function addToLock(uint256 amount) external returns (uint256);

    /// @notice Withdraws locked CHEDDA after the lock expires
    /// @dev A lock must exist and must have already expired for this call to succeed.
    /// @return The amount of CHEDDA withdrawn. This is equal to the total amount of 
    /// CHEDDA previously locked by the caller.
    function withdraw() external returns (uint256);

    /// @notice Returns the `Lock` struct for the given account.
    /// @dev Note: A `Lock` is always returned by this function.
    /// If a valid lock exists, the `amount` field is non-zero. A zero `amount`
    /// means a valid lock does not exist.
    /// @param account THe account to return the lock for.
    /// @return The lock info.
    function getLock(address account) external view returns (Lock memory);

    /// @notice Claim pending rewards for another account.
    /// @dev Emits `RewardsClaimed(address, uint)` event.
    /// Can only be called by `AccountActor` contract.
    /// @return The amount claimed
    function claimFor(address account) external returns (uint256);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ILockingGauge, Lock, LockTime} from "./ILockingGauge.sol";
import {ICheddaToken} from "../tokens/ICheddaToken.sol";
import {IAddressRegistry} from "../config/IAddressRegistry.sol";

/// @title CheddaLockingGauge
/// @notice Manages the amount of CHEDDA locked in each pool.
contract CheddaLockingGauge is ILockingGauge, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeERC20 for ICheddaToken;

    /// @notice Emitted when a lock is created or updated.
    /// @param account The account creating a lock.
    /// @param amount The amount locked. 
    /// @param expiry The lock expiry
    event LockCreated(address indexed account, uint256 amount, uint256 expiry);

    /// @notice Emitted when a lock is extended or has more CHEDDA added to added.
    /// @param account The account creating a lock.
    /// @param amount The amount locked. 
    /// @param expiry The lock expiry
    event LockModified(address indexed account, uint256 amount, uint256 expiry);
    
    /// @notice Emitted when a lock is destroyed and locked tokens are withdrawn.
    /// @param account The account creating a lock.
    /// @param amount The amount locked. 
    event Withdrawn(address indexed account, uint256 amount);
    
    /// @notice Emitted when rewards are claimed.
    /// @param account The account claiming rewards.
    /// @param amount The amount claimed.
    event Claimed(address indexed account, uint256 amount);

    /// @notice Emmitted when rewards are added to this gauge
    /// @param caller The caller of the function that emitted this event.
    /// @param amount The amount of rewards added.
    event RewardsAdded(address indexed caller, uint256 amount);

    error ReducedLockTime();
    error InvalidLockTime(LockTime);
    error LockExists(address);
    error LockNotFound(address);
    error LockNotExpired(uint256);
    error ZeroAmount();
    error InvalidAmount(uint256);

    /// @dev Thrown when account other than rewardsDistributor calls the `addRewards()` function.
    error NotAuthorized(address caller);

    IAddressRegistry public registry;
    ICheddaToken public token;
    uint256 public rewardPerShare;
    uint256 public totalLocked;
    uint256 public totalClaimed;
    uint256 public totalRewards;
    uint256 public totalWeight;
    uint256 public numberOfLocks;

    uint256 constant private MAXBOOST = 400;
    mapping (address => Lock) private locks;

    constructor(address _registry) {
        registry = IAddressRegistry(_registry);
        token = ICheddaToken(registry.cheddaToken());
    }

    modifier onlyAccountActor() {
        if (msg.sender != registry.accountActor()) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc ILockingGauge
    function createLock(uint256 amount, LockTime time) external returns (uint256) {
        token.rebase();
        Lock storage lock = locks[msg.sender];
        if (lock.amount != 0) {
            revert LockExists(msg.sender);
        }
        uint256 endTime = _getNewLockExpiry(time);
        if (endTime == 0) {
            revert InvalidLockTime(time);
        }
        if (amount == 0) {
            revert ZeroAmount();
        }
        numberOfLocks += 1;
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 weightedAmount = amount * _boostFactor(time) / MAXBOOST;

        lock.amount = amount;
        lock.expiry = endTime;
        lock.lockTime = time;
        lock.timeWeighted = weightedAmount;
        lock.rewardDebt = lock.timeWeighted * rewardPerShare / 1e12;

        totalLocked += amount;
        totalWeight += weightedAmount;

        emit LockCreated(msg.sender, amount, lock.expiry);
        return lock.expiry;
    }

    /// @inheritdoc ILockingGauge
    function extendLock(LockTime time) external returns (uint256) {
        token.rebase();

        Lock storage lock = locks[msg.sender];
        if (lock.amount == 0) {
            revert LockNotFound(msg.sender);
        }
        uint256 expiry = _getNewLockExpiry(time);
        if (lock.expiry > expiry) {
            revert ReducedLockTime();
        }
        _claimFor(msg.sender);

        totalWeight -= lock.timeWeighted;

        uint256 weightedAmount = lock.amount * _boostFactor(time) / MAXBOOST;
        lock.expiry = expiry;
        lock.lockTime = time;
        lock.timeWeighted = weightedAmount;
        lock.rewardDebt = lock.timeWeighted * rewardPerShare / 1e12;
        totalWeight += weightedAmount;
        emit LockModified(msg.sender, lock.amount, lock.expiry);

        return lock.expiry;
    }

    /// @inheritdoc ILockingGauge
    function addToLock(uint256 amount) external returns (uint256) {
        token.rebase();

        Lock storage lock = locks[msg.sender];
        if (lock.amount == 0) {
            revert LockNotFound(msg.sender);
        }
        if (amount == 0) {
            revert ZeroAmount();
        }
        _claimFor(msg.sender);
        totalWeight -= lock.timeWeighted;

        token.safeTransferFrom(msg.sender, address(this), amount);
        lock.amount += amount;
        uint256 weightedAmount = lock.amount * _boostFactor(lock.lockTime) / MAXBOOST;
        lock.timeWeighted = weightedAmount;
        lock.rewardDebt = lock.timeWeighted * rewardPerShare / 1e12;

        totalLocked += amount;
        totalWeight += weightedAmount;

        emit LockModified(msg.sender, lock.amount, lock.expiry);

        return lock.amount;
    }

    /// @dev Gets the expiry time for a lock created now, determined by the LockTime passed in.
    function _getNewLockExpiry(LockTime time) private view returns (uint256) {
        uint256 endTime = 0;
        uint256 ts = block.timestamp;

        if (time == LockTime.zero) {
            // TODO: revert this
            // revert InvalidLockTime(time);
            endTime = ts + 1 hours;
        } else if (time == LockTime.thirtyDays) {
            endTime = ts + 30 days;
        } else if (time == LockTime.ninetyDays) {
            endTime = ts + 90 days;
        } else if (time == LockTime.oneEightyDays) {
            endTime = ts + 180 days;
        } else if (time == LockTime.threeSixtyDays) {
            endTime = ts + 360 days;
        } else {
            revert InvalidLockTime(time);
        }
        return endTime;
    }

    /// @inheritdoc ILockingGauge
    function withdraw() external nonReentrant() returns (uint256) {
        token.rebase();

        Lock storage lock = locks[msg.sender];
        uint256 amount = lock.amount;
        if (amount == 0) {
            revert LockNotFound(msg.sender);
        }
        if (lock.expiry > block.timestamp) {
            revert LockNotExpired(lock.expiry);
        }

        _claimFor(msg.sender);

        totalLocked -= amount;
        totalWeight -= lock.timeWeighted;
        numberOfLocks -= 1;

        lock.amount = 0;
        lock.expiry = 0;
        lock.timeWeighted = 0;
        lock.rewardDebt = 0;
        lock.lockTime = LockTime.zero;

        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
        
        return amount;
    }

    /// @inheritdoc ILockingGauge
    function getLock(address account) external view returns (Lock memory) {
        return locks[account];
    }

    /// @inheritdoc ILockingGauge
    function claim() external returns (uint256) {
        token.rebase();
        return _claimFor(msg.sender);
    }

    /// @inheritdoc ILockingGauge
    function claimFor(address account) external onlyAccountActor() returns (uint256) {
        return _claimFor(account);
    }

    /// @dev Internal claim function.
    function _claimFor(address account) internal returns (uint256) {
        uint256 amount = claimable(account);
        if (amount != 0) {
            Lock storage lock = locks[account];
            lock.rewardDebt = lock.timeWeighted * rewardPerShare / 1e12;
            totalClaimed += amount;
            token.safeTransfer(account, amount);
            emit Claimed(account, amount);
        }
        return amount;
    }

    /// @inheritdoc ILockingGauge
    function claimable(address account) public view returns (uint256) {
        Lock storage lock = locks[account];
        return (lock.timeWeighted * rewardPerShare) / 1e12 - lock.rewardDebt;
    }

    /// @inheritdoc ILockingGauge
    function addRewards(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (amount < 1e12) {
            revert InvalidAmount(amount);
        }
        totalRewards += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        _updatePool(amount);

        emit RewardsAdded(msg.sender, amount);
    }

    /// @dev Returns the boost factor for a given lock time.
    function _boostFactor(LockTime time) private pure returns (uint256) {
        if (time == LockTime.thirtyDays) {
            return 25;
        } else if (time == LockTime.ninetyDays) {
            return 100;
        } else if (time == LockTime.oneEightyDays) {
            return 200;
        } else if (time == LockTime.threeSixtyDays) {
            return 400;
        } else if (time == LockTime.zero) {
            return 10; // TODO: revert to invalid after testing
        }
        revert InvalidLockTime(time);
    }

    /// @dev Updates the reward per share to account for `amount` rewards being added
    function _updatePool(uint256 amount) private {
        if (totalLocked == 0 || amount == 0) {
            return;
        }
        rewardPerShare += (amount * 1e12) / totalWeight;
    }
}

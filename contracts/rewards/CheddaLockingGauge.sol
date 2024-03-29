// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ILockingGauge, Lock, LockTime} from "./ILockingGauge.sol";
import {IRebaseToken} from "../tokens/IRebaseToken.sol";

contract CheddaLockingGauge is ILockingGauge, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeERC20 for IRebaseToken;

    /// @notice Emitted when a lock is created or updated.
    /// @param account The account creating a lock.
    /// @param amount The amount locked. 
    event LockCreated(address indexed account, uint256 amount, uint256 expiry);
    
    event Withdrawn(address indexed account, uint256 amount);
    
    event Claimed(address indexed account, uint256 amount);

    event RewardsAdded(address indexed caller, uint256 amount);

    error ReducedLockTime();
    error InvalidTime(LockTime);
    error LockNotExpired(uint256);
    error NoLockFound(address);
    error ZeroAmount();
    error InvalidAmount(uint256);

    IRebaseToken public token;
    uint256 public rewardPerShare;
    uint256 public totalLocked;
    uint256 public totalClaimed;
    uint256 public totalRewards;
    uint256 public weight;
    uint256 public numberOfLocks;

    uint256 constant private MAXBOOST = 400;
    mapping (address => Lock) private locks;

    constructor(address _token) {
        token = IRebaseToken(_token);
    }

    /// @inheritdoc	ILockingGauge
    function createLock(uint256 amount, LockTime time) external returns (uint256) {
        token.rebase();
        uint256 endTime;
        uint256 ts = block.timestamp;
        if (time == LockTime.thirtyDays) {
            endTime = ts + 30 days;
        } else if (time == LockTime.ninetyDays) {
            endTime = ts + 90 days;
        } else if (time == LockTime.oneEightyDays) {
            endTime = ts + 180 days;
        } else if (time == LockTime.threeSixtyDays) {
            endTime = ts + 360 days;
        } else {
            revert InvalidTime(time);
        }
        Lock storage lock = locks[msg.sender];
        if (lock.expiry > endTime) {
            revert ReducedLockTime();
        }
        if (lock.amount == 0 && amount == 0) {
            revert ZeroAmount();
        }
        if (lock.amount == 0) {
            numberOfLocks += 1;
        }

        if (amount != 0) {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
        uint256 weightedAmount = amount * _boostFactor(time) / MAXBOOST;
        lock.amount += amount;
        lock.expiry = endTime;
        lock.lockTime = time;

        lock.timeWeighted += weightedAmount;
        lock.rewardDebt = lock.timeWeighted * rewardPerShare / 1e12;
        totalLocked += amount;
        weight += weightedAmount;

        emit LockCreated(msg.sender, amount, lock.expiry);
        return lock.expiry;
    }

    /// @inheritdoc	ILockingGauge
    function withdraw() external nonReentrant() returns (uint256) {
        token.rebase();
        Lock storage lock = locks[msg.sender];
        uint256 amount = lock.amount;
        if (amount == 0) {
            revert NoLockFound(msg.sender);
        }
        if (lock.expiry > block.timestamp) {
            revert LockNotExpired(lock.expiry);
        }

        _claim(msg.sender);

        totalLocked -= amount;
        weight -= lock.timeWeighted;
        numberOfLocks -= 1;

        lock.amount = 0;
        lock.expiry = 0;
        lock.timeWeighted = 0;
        lock.rewardDebt = 0;

        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
        
        return amount;
    }

    /// @inheritdoc	ILockingGauge
    function getLock(address account) external view returns (Lock memory) {
        return locks[account];
    }

    /// @inheritdoc	ILockingGauge
    function claim() external returns (uint256) {
        return _claim(msg.sender);
    }

    /// @dev Internal claim function.
    function _claim(address account) internal returns (uint256) {
        token.rebase();
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

    /// @inheritdoc	ILockingGauge
    function claimable(address account) public view returns (uint256) {
        Lock storage lock = locks[account];
        return (lock.timeWeighted * rewardPerShare) / 1e12 - lock.rewardDebt;
    }

    /// @inheritdoc	ILockingGauge
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
        }
        revert InvalidTime(time);
    }

    /// @dev Updates the reward per share to account for `amount` rewards being added
    function _updatePool(uint256 amount) private {
        if (totalLocked == 0 || amount == 0) {
            return;
        }
        rewardPerShare += (amount * 1e12) / weight;
    }
}

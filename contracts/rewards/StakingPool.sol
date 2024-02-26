// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAddressRegistry} from "../config/IAddressRegistry.sol";
import {IStakingPool} from "./IStakingPool.sol";

/// @title StakingPool
/// @notice Manages LP staking rewards
contract StakingPool is IStakingPool {

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event RewardsAdded(uint256 amount);

    error NotAuthorized(address caller);
    error NoStakeFound(address caller);
    error InsufficientStake();
    error ZeroAmount();

    using SafeERC20 for ERC20;
    using SafeERC20 for IERC20;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    IAddressRegistry public registry;

    uint256 public lifetimeRewards;
    uint256 public lifetimeClaimed;
    uint256 public totalStaked;

    /// @dev mapping account to staked tokens
    mapping (address => uint256) public stakingBalance;

    /// @dev mapping time to cumulative rewards 
    mapping (uint256 => uint256) public tokenCheckpoints;

    /// @dev mapping account cumulative rewards
    mapping (address => uint256) public accountCheckpoints;

    mapping (address => uint256) public accountClaimed;

    constructor(address _staking, address _rewards, address _registry) {
        stakingToken = IERC20(_staking);
        rewardsToken = IERC20(_rewards);
        registry = IAddressRegistry(_registry);
    }

    modifier onlyRewarder() {
        if (msg.sender != registry.rewardsDistributor()) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    function stake(uint256 amount) external {
        // if already staking, add to stake
        // handle fresh stake only
        // handle if stake already exists
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (_isStaking(msg.sender)) {
            _claim(msg.sender);
        }
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        totalStaked += amount;
        accountCheckpoints[msg.sender] = lifetimeRewards;
        stakingBalance[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (!_isStaking(msg.sender)) {
            revert NoStakeFound(msg.sender);
        }
        _claim(msg.sender);
        totalStaked -= amount;
        if (amount == stakingBalance[msg.sender]) {
            delete accountCheckpoints[msg.sender];
            delete stakingBalance[msg.sender];
        } else {
            accountCheckpoints[msg.sender] = lifetimeRewards;
            stakingBalance[msg.sender] -= amount;
        }
        stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /// total claimable rewards by all users
    function pendingRewards() external view returns (uint256) {
        return lifetimeRewards - lifetimeClaimed;
    }

    function claimableRewards(address account) external view returns (uint256) {
        return _calculateRewards(account);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function _claim(address account) private {
        uint256 amount = _calculateRewards(account);
        if (amount != 0) {
            _updateRewards(account, amount);
            rewardsToken.safeTransfer(account, amount);

            emit Claimed(account, amount);
        }
    }

    function _updateRewards(address account, uint256 amount) internal {
        accountClaimed[account] += amount;
        lifetimeClaimed += amount;
    }

    function _calculateRewards(address account) internal view returns (uint256) {
        // share = stakedBalance[mine] / totalStaked * (totalRewards - accountCheckpoint[mine]) - claimedRewards
        if (totalStaked == 0) {
            return 0;
        }
        uint256 currentRewards = lifetimeRewards - accountCheckpoints[account];
        if (currentRewards == 0) {
            return 0;
        }
        uint256 share = currentRewards * stakingBalance[account] / totalStaked;
        if (share < accountClaimed[account]) {
            return 0;
        }
        return share - accountClaimed[account];
    }

    function _isStaking(address account) private view returns (bool) {
        return stakingBalance[account] != 0;
    }

    function addRewards(uint256 amount) external onlyRewarder() {
        if (amount == 0) {
            revert ZeroAmount();
        }
        rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
        lifetimeRewards += amount;

        emit RewardsAdded(amount);
    }
}

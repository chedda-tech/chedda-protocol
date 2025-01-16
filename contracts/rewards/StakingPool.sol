// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAddressRegistry} from "../config/AddressRegistry.sol";
import {IStakingPool} from "./IStakingPool.sol";
import {ICheddaToken} from "./ICheddaToken.sol";

/// @title StakingPool
/// @notice Manages staking tokens and rewards.
/// Use cases: LendigPool LP staking, $CHEDDA token LP token.
contract StakingPool is IStakingPool {

    using SafeERC20 for IERC20;
    using SafeERC20 for ICheddaToken;

    /// @notice Emitted when a user stakes tokens.
    /// @param account The account that staked.
    /// @param amount The amount staked.
    event Staked(address indexed account, uint256 amount);

    /// @notice Emitted when a user unstakes tokens.
    /// @param account The account that unstaked.
    /// @param amount The amount unstaked.
    event Unstaked(address indexed account, uint256 amount);

    /// @notice Emitted when rewards are claimed.
    /// @param account The account that claimed.
    /// @param amount The amount wclaimed.
    event RewardsClaimed(address indexed account, uint256 amount);

    /// @notice Emitted when rewards are added to the reward pool.
    /// @param amount The amount added.
    event RewardsAdded(uint256 amount);

    /// @dev Thrown when user tries to unstake more than their staking balance.
    error InsufficientStake();
    
    /// @dev Thrown when user tries to stake or unstake the zero amount.
    error ZeroAmount();

    /// @dev Thrown when a zero address is specified.
    error ZeroAddress();

    /// @dev Thrown when an invalid amount of rewards are added.
    error InvalidAmount(uint256 amount);

    // @dev structure for keeping track of staking balance and reward rate at time of staking.
    struct UserInfo {
        uint256 amountStaked;
        uint256 rewardDebt; // Accumulated reward debt
    }

    mapping(address => UserInfo) public userInfo;

    /// @notice The staking token
    IERC20 public immutable stakingToken; // Token being staked

    /// @notice The reward token
    ICheddaToken public immutable rewardToken; // Token for rewards

    IAddressRegistry public immutable registry;

    /// @notice Total amount of tokens staked
    uint256 public totalStaked;

    /// @notice The number of unique stakers
    uint256 public stakers;

    /// @notice Current reward per share
    uint256 public rewardPerShare;

    /// @notice Constructor
    /// @param _registry The Chedda AddressRegistry
    /// @param _stakingToken The token being staked.
    constructor(address _registry, address _stakingToken) {
        require (_registry != address(0) && _stakingToken != address(0),
            ZeroAddress());
        registry = IAddressRegistry(_registry);
        stakingToken = IERC20(_stakingToken);
        rewardToken = ICheddaToken(registry.cheddaToken());
    }

    /// @inheritdoc IStakingPool
    function stake(uint256 amount) external returns (uint256) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        uint256 amountClaimed = 0;
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);

        UserInfo storage user = userInfo[msg.sender];
        if (user.amountStaked > 0) {
            uint256 pendingReward = claimable(msg.sender);
            if (pendingReward > 0) {
                amountClaimed = claim();
            }
        } else {
            stakers += 1;
        }
        user.amountStaked += amount;
        user.rewardDebt = user.amountStaked * rewardPerShare / 1e12;
        totalStaked += amount;

        rewardToken.rebase();

        emit Staked(msg.sender, amount);
        return amountClaimed;
    }

    /// @inheritdoc IStakingPool
    function unstake(uint256 amount) external returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];
        if (user.amountStaked < amount) {
            revert InsufficientStake();
        }

        rewardToken.rebase();
        
        uint256 pendingReward = claimable(msg.sender);
        uint256 claimed = 0;
        if (pendingReward > 0) {
            claimed = claim();
        }

        user.amountStaked -= amount;
        user.rewardDebt = user.amountStaked * rewardPerShare / 1e12;
        totalStaked -= amount;
        IERC20(stakingToken).safeTransfer(msg.sender, amount);

        if (user.amountStaked == 0) {
            stakers -= 1;
        }

        emit Unstaked(msg.sender, amount);

        return claimed;
    }

    /// @inheritdoc IStakingPool
    function claim() public returns (uint256) {
        rewardToken.rebase();
        return _claimFor(msg.sender);
    }

    function claimFor(address account) public returns (uint256 claimed) {
        rewardToken.rebase();
        claimed = _claimFor(account);
    }

    /// @dev Internal claim function
    function _claimFor(address account) private returns (uint256) {
        uint256 claimAmount = claimable(account);
        if (claimAmount != 0) {
            UserInfo storage user = userInfo[account];
            user.rewardDebt = user.amountStaked * rewardPerShare / 1e12;
            IERC20(rewardToken).safeTransfer(account, claimAmount);

            emit RewardsClaimed(account, claimAmount);
        }        
        return claimAmount; 
    }

    /// @inheritdoc IStakingPool
    function claimable(address account) public view returns (uint256) {
        UserInfo storage user = userInfo[account];
        return (user.amountStaked * rewardPerShare) / 1e12 - user.rewardDebt;
    }

    /// @inheritdoc IStakingPool
    function stakingBalance(address account) external view returns (uint256) {
        return userInfo[account].amountStaked;
    }

    /// @inheritdoc IStakingPool
    function addRewards(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (amount < 1e12) {
            revert InvalidAmount(amount);
        }
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        _updatePool(amount);

        emit RewardsAdded(amount);
    }

    /// @dev Updates the reward per share to account for `amount` rewards being added
    function _updatePool(uint256 amount) private {
        if (totalStaked == 0 || amount == 0) {
            return;
        }
        rewardPerShare += (amount * 1e12) / totalStaked;
    }
}

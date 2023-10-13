// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IRebaseToken } from "./IRebaseToken.sol";

/// @title Staked Chedda
/// @notice Tokenized vault representing staked CHEDDA rewards.
/// @dev Must be set as CHEDDA token vault for new token emission.
contract StakedChedda is ERC4626 {

    /// @notice Emitted when CHEDDA is staked.
    /// @param account The account that staked.
    /// @param amount The amount of CHEDDA staked.
    /// @param shares The amount of xCHEDDA minted.
    event Staked(address indexed account, uint256 amount, uint256 shares);

    /// @notice Emitted when CHEDDA is unstaked.
    /// @param account The account that unstaked.
    /// @param amount The amount of CHEDDA unstaked.
    /// @param shares The amount of xCHEDDA burned.
    event Unstaked(address indexed account, uint256 amount, uint256 shares);

    IRebaseToken public chedda;

    constructor(address _chedda) 
    ERC4626(IERC20(_chedda))
    ERC20("Staked Chedda", "xCHEDDA") {
        chedda = IRebaseToken(_chedda);
    }

    /// @notice Total amount of CHEDDA staked.
    /// @return Amount of CHEDDA staked
    function totalAssets() public override view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /// @notice Stake CHEDDA.
    /// @dev mints xCHEDDA
    /// @param amount Amount to stake.
    /// @return shares Amount of xCHEDDA minted.
    function stake(uint256 amount) public returns (uint256 shares) {
        shares = deposit(amount, msg.sender);
        chedda.rebase();
        emit Staked(msg.sender, amount, shares);
    }

    /// @notice Unstake CHEDDA.
    /// @dev burns xCHEDDA.
    /// @param shares Shares of xCHEDDA to redeem
    /// @return amount Amount of CHEDDA retruned by redeeming xCHEDDA.
    function unstake(uint256 shares) public returns (uint256 amount) {
        chedda.rebase();
        amount = redeem(shares, msg.sender, msg.sender);
        emit Unstaked(msg.sender, amount, shares);
    }
}

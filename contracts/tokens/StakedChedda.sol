// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IRebaseToken } from "./IRebaseToken.sol";

/// @title Staked Chedda
/// @notice Tokenized vault representing staked CHEDDA rewards.
/// @dev Must be set as CHEDDA token vault for new token emission.
contract StakedChedda is ERC4626 {

    event Staked(address indexed account, uint256 amount, uint256 shares);
    event Unstaked(address indexed account, uint256 amount, uint256 shares);

    IRebaseToken public chedda;

    constructor(address _chedda) 
    ERC4626(IERC20(_chedda))
    ERC20("Staked Chedda", "xCHEDDA") {
        chedda = IRebaseToken(_chedda);
    }

    /// @notice Total amount of Chedda staked.
    /// @return Amount of Chedda staked
    function totalAssets() public override view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /// @notice Stake Chedda.
    /// @param amount Amount to stake.
    /// @dev mints xChedda
    /// @return shares Amount of xChedda minted.
    function stake(uint256 amount) public returns (uint256 shares) {
        shares = deposit(amount, msg.sender);
        chedda.rebase();
        emit Staked(msg.sender, amount, shares);
    }

    /// @notice Unstake Chedda.
    /// @param shares Shares of xChedda to redeem
    /// @dev burns xChedda
    /// @return amount Amount of Chedda retruned by redeeming xChedda.
    function unstake(uint256 shares) public returns (uint256 amount) {
        chedda.rebase();
        amount = redeem(shares, msg.sender, msg.sender);
        emit Unstaked(msg.sender, amount, shares);
    }
}

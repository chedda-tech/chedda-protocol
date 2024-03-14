// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CheddaToken } from "../contracts/tokens/CheddaToken.sol";
import { StakedChedda, ERC20 } from "../contracts/tokens/StakedChedda.sol";

contract StakedCheddaTest is Test {

    CheddaToken public chedda;
    StakedChedda public xChedda;
    address public bob;

    function setUp() external {
        bob = makeAddr("bob");
        chedda = new CheddaToken(bob);
        xChedda = new StakedChedda(address(chedda));
    }

    function testStaking() external {
        uint256 amount = 1000e18;
        emit log_named_address("bob's address", bob);
        uint256 bobBalance = chedda.balanceOf(bob);
        emit log_named_uint("bob's balance", bobBalance);

        vm.startPrank(bob);
        vm.expectRevert();
        // vm.expectRevert(ERC20.ERC20InsufficientAllowance.selector);

        // not yet approved
        uint256 shares = xChedda.stake(amount);

        chedda.approve(address(xChedda), amount);
        shares = xChedda.stake(amount);
        emit log_named_uint("xChedda shares", shares);
        assertEq(shares, xChedda.balanceOf(bob));

        uint256 bobNewBalance = chedda.balanceOf(bob);
        assertEq(bobNewBalance, bobBalance - amount);
    }

    function testUnstaking() external {
        uint256 amount = 1000e18;
        vm.startPrank(bob);
        uint256 bobBalanceInitial = chedda.balanceOf(bob);
        chedda.approve(address(xChedda), amount);
        uint256 shares = xChedda.stake(amount);
        
        uint256 bobBalanceAfterStake = chedda.balanceOf(bob);
        assertEq(bobBalanceAfterStake, bobBalanceInitial - amount);

        uint256 unstakedAmount = xChedda.unstake(shares);
        uint256 bobBalanceAfterUnstake = chedda.balanceOf(bob);
        assertEq(unstakedAmount, amount);
        assertEq(bobBalanceAfterUnstake, bobBalanceInitial);
    }

    function testTotalAssets() external {
        uint256 amount = 1000e18;
        vm.startPrank(bob);
        chedda.approve(address(xChedda), amount);
        xChedda.stake(amount);
        uint256 totalAssets = xChedda.totalAssets();
        assertEq(totalAssets, amount);
    }

    function testPieSizeIncreases() external {
       uint256 amount = 1000e18;
        vm.startPrank(bob);
        chedda.approve(address(xChedda), amount);
        uint256 shares = xChedda.stake(amount); 

        chedda.transfer(address(xChedda), amount);
        assertEq(xChedda.totalAssets(), amount * 2);

        uint256 amountReturned = xChedda.unstake(shares);
        emit log_named_uint("amountReturned", amountReturned);
        emit log_named_uint("amount times 2", amount * 2);

        // account for rounding down when converting shares to assets
        assertApproxEqAbs(amountReturned, amount * 2, 1);
    }
}

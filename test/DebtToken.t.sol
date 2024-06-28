// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import { DebtToken } from "../contracts/tokens/DebtToken.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract DebtTokenTest is Test {

    DebtToken private _debtToken;
    MockERC20 private _asset;
    address public bob;
    address public alice;
    address public vault;

    function setUp() public {
        bob = makeAddr("bob");
        alice = makeAddr("alice");
        vault = makeAddr("vault");
        _asset = new MockERC20("Token", "TOK", 18, 1_000_000 * 1e18);
        _debtToken = new DebtToken(_asset, vault);
        vm.warp(1641070800);
    }

    function testReverts() public {
        uint256 amount = 1000e18;

        // checks reverts if not call
        vm.expectRevert(DebtToken.NotVault.selector);
        _debtToken.createDebt(amount, bob);

        vm.expectRevert(DebtToken.NotVault.selector);
        _debtToken.repayAmount(amount, bob);

        vm.expectRevert(DebtToken.NotVault.selector);
        _debtToken.repayShare(amount, bob);
    }

    function testCreateDebt() external {
        uint256 amount = 1000e18;

        vm.startPrank(vault);

        uint256 expectedShares = _debtToken.createDebt(amount, bob);
        uint256 bobShares = _debtToken.balanceOf(bob);
        assertEq(bobShares, expectedShares);
        assertEq(bobShares, _debtToken.accountShare(bob));
        assertEq(bobShares, _debtToken.totalSupply());

        assertGe(_debtToken.totalDebt(), amount);
    }

    // check initial state
    // create debt
    // -- check debt amount and assetsPerShare
    // add interest
    // -- check debt is the same, assetsPerShare increased by amount of interest added
    function testDebtGrows() external {
        uint256 amount = 1000e18;
        uint256 interestAmount = amount * 0.1e18 / 1e18; // 10% interest

        vm.startPrank(vault);
        // initial state
        uint256 debtT0 = _debtToken.totalAssets();
        uint256 assetsPerShareT0 = _debtToken.assetsPerShare();
        assertEq(debtT0, 0);
        assertEq(assetsPerShareT0, 1e18);

        _debtToken.createDebt(amount, bob); 
        uint256 debtT1 = _debtToken.totalAssets();
        uint256 assetsPerShareT1 = _debtToken.assetsPerShare();
        uint256 totalSupplyT1 = _debtToken.totalSupply();
        assertEq(amount, debtT1);
        assertEq(assetsPerShareT0, assetsPerShareT1);
        assertGt(debtT1, debtT0);

        // add 10% interest
        _debtToken.addInterest(interestAmount);
        assertEq(_debtToken.totalSupply(), totalSupplyT1);
        assertEq(_debtToken.assetsPerShare(), assetsPerShareT1 * 1.1e18 / 1e18);
        assertEq(_debtToken.totalDebt(), debtT1 * 1.1e18 / 1e18);
        assertEq(_debtToken.totalDebt(), debtT1 + interestAmount);
    }

    function testRepayAmount() external {
       uint256 amount = 1000e18;

        vm.startPrank(vault);

        uint256 shares = _debtToken.createDebt(amount, bob);
        uint256 sharesRepaid = _debtToken.repayAmount(amount, bob);

        assertLe(sharesRepaid, shares); 
        uint256 sharesAfterRepayment = _debtToken.balanceOf(bob);
        assertGt(shares, sharesAfterRepayment);
    }

    function testRepayShare() external {
        uint256 amount = 1000e18;

        vm.startPrank(vault);

        uint256 shares = _debtToken.createDebt(amount, bob);
        uint256 amountRepaid = _debtToken.repayShare(shares, bob);

        assertGe(amountRepaid, amount); 
        uint256 bobSharesAfterRepayment = _debtToken.balanceOf(bob);
        assertEq(0, bobSharesAfterRepayment);
    }

    function testTransfersRevert() external {
       uint256 amount = 1000e18;

        vm.startPrank(vault);

        uint256 shares = _debtToken.createDebt(amount, bob); 
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(DebtToken.NonTransferrable.selector));
        _debtToken.transfer(alice, shares);
        _debtToken.approve(address(vault), shares);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(DebtToken.NonTransferrable.selector));
        _debtToken.transferFrom(bob, alice, shares);
    }

    function testZeroAmountsRevert() external {
        uint256 zero = 0;
        vm.startPrank(vault);
        vm.expectRevert(abi.encodeWithSelector(DebtToken.ZeroShares.selector));
        _debtToken.createDebt(zero, bob);

        vm.expectRevert(abi.encodeWithSelector(DebtToken.ZeroAssets.selector));
        _debtToken.repayShare(zero, bob);

        vm.expectRevert(abi.encodeWithSelector(DebtToken.ZeroShares.selector));
        _debtToken.repayAmount(zero, bob);
    }
}

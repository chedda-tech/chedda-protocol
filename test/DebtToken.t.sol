// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
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
        _asset = new MockERC20("Token", "TOK", 18, 1_000_000 * 1e18);
        _debtToken = new DebtToken(_asset, vault);
    }

    function testReverts() public {
        uint256 amount = 1000 * 1e18;

        // checks reverts if not call
        vm.expectRevert(DebtToken.NotVault.selector);
        _debtToken.createDebt(amount, bob);

        vm.expectRevert(DebtToken.NotVault.selector);
        _debtToken.repayAmount(amount, bob);

        vm.expectRevert(DebtToken.NotVault.selector);
        _debtToken.repayShare(amount, bob);
    }

    function testCreateDebt() external {
        uint256 amount = 1000 * 1e18;

        vm.startPrank(vault);

        uint256 expectedShares = _debtToken.createDebt(amount, bob);
        uint256 bobShares = _debtToken.balanceOf(bob);
        assertEq(bobShares, expectedShares);
        assertEq(bobShares, _debtToken.accountShare(bob));
        assertEq(bobShares, _debtToken.totalSupply());

        // totalBorrowed = borrowed + interest
        assertGe(_debtToken.totalDebt(), amount);
    }

    function testDebtGrows() external {
        uint256 amount = 1000 * 1e18;

        vm.startPrank(vault);
        uint256 debtT0 = _debtToken.totalAssets();
        uint256 assetsPerShareT0 = _debtToken.assetsPerShare();
        assertEq(debtT0, 0);
        assertEq(assetsPerShareT0, 1e18);

        _debtToken.createDebt(amount, bob); 
        uint256 debtT1 = _debtToken.totalAssets();
        uint256 assetsPerShareT1 = _debtToken.assetsPerShare();
        assertGt(debtT1, debtT0);
        assertGt(assetsPerShareT1, assetsPerShareT0);

        // debt grows over time
        vm.warp(block.timestamp + 1000);
        _debtToken.accrue();
        uint256 debtT2 = _debtToken.totalAssets();
        uint256 assetsPerShareT2 = _debtToken.assetsPerShare();
        assertGt(debtT2, debtT1);
        assertGt(assetsPerShareT2, assetsPerShareT1);
    }

    function testRepayAmount() external {
       uint256 amount = 1000 * 1e18;

        vm.startPrank(vault);

        uint256 shares = _debtToken.createDebt(amount, bob);
        uint256 sharesRepaid = _debtToken.repayAmount(amount, bob);

        assertLe(sharesRepaid, shares); 
        uint256 sharesAfterRepayment = _debtToken.balanceOf(bob);
        assertGt(shares, sharesAfterRepayment);
    }

    function testRepayShare() external {
        uint256 amount = 1000 * 1e18;

        vm.startPrank(vault);

        uint256 shares = _debtToken.createDebt(amount, bob);
        uint256 amountRepaid = _debtToken.repayShare(shares, bob);

        assertGe(amountRepaid, amount); 
        uint256 bobSharesAfterRepayment = _debtToken.balanceOf(bob);
        assertEq(0, bobSharesAfterRepayment);
    }

    function testTransfersRevert() external {
       uint256 amount = 1000 * 1e18;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {CheddaLockingGauge} from "../contracts/rewards/CheddaLockingGauge.sol";
import {Lock, LockTime} from "../contracts/rewards/ILockingGauge.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockRebaseERC20} from "./mocks/MockRebaseERC20.sol";

contract CheddaLockingGaugeTest is Test {

    CheddaLockingGauge public gauge;
    MockRebaseERC20 public token;
    address alice;
    address bob;
    address carol;
    address dean;
    address minter;

    function setUp() external {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");
        dean = makeAddr("dean");
        minter = makeAddr("minter");

        token = new MockRebaseERC20("mock", "mock", 18, 1_000_000e18, minter);
        gauge = new CheddaLockingGauge(address(token));

        token.mint(alice, 1_000_000e18);
        token.mint(bob, 1_000_000e18);
        token.mint(carol, 1_000_000e18);
        token.mint(dean, 1_000_000e18);
    }

    function testCreateLock() external {
        uint256 amount = 1000e18;

        uint256 initialBobBalance = token.balanceOf(bob);
        vm.startPrank(bob);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.thirtyDays);
        Lock memory lock = gauge.getLock(bob);
        vm.stopPrank();

        assertEq(gauge.totalLocked(), amount);
        assertEq(lock.amount, amount);
        assertEq(initialBobBalance - amount, token.balanceOf(bob));
        assertApproxEqAbs(lock.expiry, block.timestamp + 30 days, 1 hours);
    }

    function testCreateMultipleLocks() external {
        uint256 amount = 1000e18;
        uint256 rewardAmount = 1000e18;
        // assertEq(true, false);

        vm.startPrank(alice);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.thirtyDays);
        vm.stopPrank();
        
        vm.startPrank(bob);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.ninetyDays);
        vm.stopPrank();

        vm.startPrank(carol);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.oneEightyDays);
        vm.stopPrank();

        vm.startPrank(dean);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.threeSixtyDays);
        vm.stopPrank();

        vm.startPrank(minter);
        token.mint(minter, rewardAmount);
        token.approve(address(gauge), rewardAmount);
        gauge.addRewards(rewardAmount);
        vm.stopPrank();

        assertEq(gauge.getLock(alice).timeWeighted * 4, gauge.getLock(bob).timeWeighted);
        assertEq(gauge.getLock(bob).timeWeighted * 2, gauge.getLock(carol).timeWeighted);
        assertEq(gauge.getLock(carol).timeWeighted * 2, gauge.getLock(dean).timeWeighted);

        assertEq(gauge.claimable(alice) * 4, gauge.claimable(bob));
        assertEq(gauge.claimable(bob) * 2, gauge.claimable(carol));
        assertEq(gauge.claimable(carol) * 2, gauge.claimable(dean));
    }

    function testCreateLockReverts() external {
       uint256 amount = 1000e18;

        vm.startPrank(bob);
        token.approve(address(gauge), amount);
        vm.expectRevert(CheddaLockingGauge.ZeroAmount.selector);
        gauge.createLock(0, LockTime.thirtyDays);
    }

    function testWithdrawLock() external {
        uint256 amount = 1000e18;
        uint256 initialBobBalance = token.balanceOf(bob);

        vm.startPrank(bob);
        token.approve(address(gauge), amount);
        uint256 expiry = gauge.createLock(amount, LockTime.thirtyDays);

        vm.expectRevert(abi.encodeWithSelector(CheddaLockingGauge.LockNotExpired.selector, expiry));
        gauge.withdraw();

        skip(30 days + 1);
        uint256 withdrawn = gauge.withdraw();
        vm.stopPrank();

        assertEq(withdrawn, amount);
        assertEq(initialBobBalance, token.balanceOf(bob));
        assertEq(gauge.claimable(bob), 0);
    }

    function testWithdrawLockRevert() external {
       uint256 amount = 1000e18;

        vm.startPrank(bob);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.thirtyDays); 
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(CheddaLockingGauge.NoLockFound.selector, alice));
        gauge.withdraw();
        vm.stopPrank();
    }

    function testClaimLock() external {
        uint256 amount = 1000e18;
        uint256 rewardAmount = 2500e18;
        uint256 mintAmount = 1_000_000e18;
        token.mint(minter, mintAmount);

        vm.startPrank(bob);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.thirtyDays);
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(gauge), amount);
        gauge.createLock(amount, LockTime.ninetyDays);
        vm.stopPrank();

        vm.startPrank(minter);
        token.approve(address(gauge), rewardAmount);
        gauge.addRewards(rewardAmount);
        vm.stopPrank();

        // alice locks for 90 days, bob for 30 days -> alice gets 4x rewards
        assertEq(gauge.claimable(bob) * 4, gauge.claimable(alice));

        vm.startPrank(bob);
        uint256 bobClaimable = gauge.claimable(bob);
        uint256 bobBalanceBefore = token.balanceOf(bob);
        gauge.claim();
        uint256 bobBalanceAfter = token.balanceOf(bob);
        assertEq(bobBalanceAfter, bobBalanceBefore + bobClaimable);
        assertEq(gauge.claimable(bob), 0);
        vm.stopPrank();
    }

    function testRelocking() external {
        uint256 amount = 1000e18;
        vm.startPrank(bob);
        token.approve(address(gauge), amount);
        uint256 initialExpiry = gauge.createLock(amount, LockTime.ninetyDays);
        Lock memory initialLock = gauge.getLock(bob);

        token.approve(address(gauge), amount);
        vm.expectRevert(CheddaLockingGauge.ReducedLockTime.selector);
        gauge.createLock(amount, LockTime.thirtyDays);
        
        uint256 newExpiry = gauge.createLock(amount, LockTime.oneEightyDays);
        Lock memory newLock = gauge.getLock(bob);

        assertApproxEqAbs(newExpiry, initialExpiry * 2, 10);
        assertEq(newLock.amount, initialLock.amount * 2);

        // new weight = initial + 2 x initial
        assertEq(newLock.timeWeighted, initialLock.timeWeighted * 3);

        vm.stopPrank(); 
    }

    function testAddRewardsReverts() external {
        vm.startPrank(minter);
        vm.expectRevert(CheddaLockingGauge.ZeroAmount.selector);
        gauge.addRewards(0);

        uint256 amount = 1e10;
        vm.expectRevert(abi.encodeWithSelector(CheddaLockingGauge.InvalidAmount.selector, amount));
        gauge.addRewards(amount);

        vm.stopPrank();
    }
}

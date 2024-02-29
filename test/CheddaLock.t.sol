// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {CheddaLock} from "../contracts/rewards/CheddaLock.sol";
import {Lock, LockTime} from "../contracts/rewards/ILockingPool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract CheddaLockTest is Test {

    CheddaLock public lockingContract;
    ERC20Mock public token;
    address alice;
    address bob;
    address carol;
    address dean;
    address minter;

    function setUp() external {
        token = new ERC20Mock();
        lockingContract = new CheddaLock(address(token));
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");
        dean = makeAddr("dean");
        minter = makeAddr("minter");
        token.mint(alice, 1_000_000e18);
        token.mint(bob, 1_000_000e18);
        token.mint(carol, 1_000_000e18);
        token.mint(dean, 1_000_000e18);
    }

    function testCreateLock() external {
        uint256 amount = 1000e18;

        uint256 initialBobBalance = token.balanceOf(bob);
        vm.startPrank(bob);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.thirtyDays);
        Lock memory lock = lockingContract.getLock(bob);
        vm.stopPrank();

        assertEq(lockingContract.totalLocked(), amount);
        assertEq(lock.amount, amount);
        assertEq(initialBobBalance - amount, token.balanceOf(bob));
        assertApproxEqAbs(lock.expiry, block.timestamp + 30 days, 1 hours);
    }

    function testCreateMultipleLocks() external {
        uint256 amount = 1000e18;
        uint256 rewardAmount = 1000e18;
        // assertEq(true, false);

        vm.startPrank(alice);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.thirtyDays);
        vm.stopPrank();
        
        vm.startPrank(bob);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.ninetyDays);
        vm.stopPrank();

        vm.startPrank(carol);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.oneEightyDays);
        vm.stopPrank();

        vm.startPrank(dean);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.threeSixtyDays);
        vm.stopPrank();

        vm.startPrank(minter);
        token.mint(minter, rewardAmount);
        token.approve(address(lockingContract), rewardAmount);
        lockingContract.addRewards(rewardAmount);
        vm.stopPrank();

        assertEq(lockingContract.getLock(alice).timeWeighted * 4, lockingContract.getLock(bob).timeWeighted);
        assertEq(lockingContract.getLock(bob).timeWeighted * 2, lockingContract.getLock(carol).timeWeighted);
        assertEq(lockingContract.getLock(carol).timeWeighted * 2, lockingContract.getLock(dean).timeWeighted);

        assertEq(lockingContract.claimable(alice) * 4, lockingContract.claimable(bob));
        assertEq(lockingContract.claimable(bob) * 2, lockingContract.claimable(carol));
        assertEq(lockingContract.claimable(carol) * 2, lockingContract.claimable(dean));
    }

    function testCreateLockReverts() external {
       uint256 amount = 1000e18;

        vm.startPrank(bob);
        token.approve(address(lockingContract), amount);
        vm.expectRevert(CheddaLock.ZeroAmount.selector);
        lockingContract.createLock(0, LockTime.thirtyDays);
    }

    function testWithdrawLock() external {
        uint256 amount = 1000e18;
        uint256 initialBobBalance = token.balanceOf(bob);

        vm.startPrank(bob);
        token.approve(address(lockingContract), amount);
        uint256 expiry = lockingContract.createLock(amount, LockTime.thirtyDays);

        vm.expectRevert(abi.encodeWithSelector(CheddaLock.LockNotExpired.selector, expiry));
        lockingContract.withdraw();

        skip(30 days + 1);
        uint256 withdrawn = lockingContract.withdraw();
        vm.stopPrank();

        assertEq(withdrawn, amount);
        assertEq(initialBobBalance, token.balanceOf(bob));
        assertEq(lockingContract.claimable(bob), 0);
    }

    function testWithdrawLockRevert() external {
       uint256 amount = 1000e18;

        vm.startPrank(bob);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.thirtyDays); 
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(CheddaLock.NoLockFound.selector, alice));
        lockingContract.withdraw();
        vm.stopPrank();
    }

    function testClaimLock() external {
        uint256 amount = 1000e18;
        uint256 rewardAmount = 2500e18;
        uint256 mintAmount = 1_000_000e18;
        token.mint(minter, mintAmount);

        vm.startPrank(bob);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.thirtyDays);
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(lockingContract), amount);
        lockingContract.createLock(amount, LockTime.ninetyDays);
        vm.stopPrank();

        vm.startPrank(minter);
        token.approve(address(lockingContract), rewardAmount);
        lockingContract.addRewards(rewardAmount);
        vm.stopPrank();

        // alice locks for 90 days, bob for 30 days -> alice gets 4x rewards
        assertEq(lockingContract.claimable(bob) * 4, lockingContract.claimable(alice));

        vm.startPrank(bob);
        uint256 bobClaimable = lockingContract.claimable(bob);
        uint256 bobBalanceBefore = token.balanceOf(bob);
        lockingContract.claim();
        uint256 bobBalanceAfter = token.balanceOf(bob);
        assertEq(bobBalanceAfter, bobBalanceBefore + bobClaimable);
        assertEq(lockingContract.claimable(bob), 0);
        vm.stopPrank();
    }

    function testRelocking() external {
        uint256 amount = 1000e18;
        vm.startPrank(bob);
        token.approve(address(lockingContract), amount);
        uint256 initialExpiry = lockingContract.createLock(amount, LockTime.ninetyDays);
        Lock memory initialLock = lockingContract.getLock(bob);

        token.approve(address(lockingContract), amount);
        vm.expectRevert(CheddaLock.ReducedLockTime.selector);
        lockingContract.createLock(amount, LockTime.thirtyDays);
        
        uint256 newExpiry = lockingContract.createLock(amount, LockTime.oneEightyDays);
        Lock memory newLock = lockingContract.getLock(bob);

        assertApproxEqAbs(newExpiry, initialExpiry * 2, 10);
        assertEq(newLock.amount, initialLock.amount * 2);

        // new weight = initial + 2 x initial
        assertEq(newLock.timeWeighted, initialLock.timeWeighted * 3);

        vm.stopPrank(); 
    }

    function testAddRewardsReverts() external {
        vm.startPrank(minter);
        vm.expectRevert(CheddaLock.ZeroAmount.selector);
        lockingContract.addRewards(0);

        uint256 amount = 1e10;
        vm.expectRevert(abi.encodeWithSelector(CheddaLock.InvalidAmount.selector, amount));
        lockingContract.addRewards(amount);

        vm.stopPrank();
    }
}

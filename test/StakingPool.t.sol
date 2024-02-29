// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {StakingPool} from "../contracts/rewards/StakingPool.sol";
import {MockAddressRegistry} from "./mocks/MockAddressRegistry.sol";
import {MockRewardsDistributor} from "./mocks/MockRewardsDistributor.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract StakingPoolTest is Test {

    StakingPool internal pool;
    ERC20Mock internal stakingToken;
    ERC20Mock internal rewardToken;
    MockAddressRegistry internal registry;
    MockRewardsDistributor internal distributor;

    address internal alice;
    address internal bob;
    address internal colin;

    function setUp() public virtual {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        colin = makeAddr("colin");
        
        stakingToken = new ERC20Mock();
        rewardToken = new ERC20Mock();
        registry = new MockAddressRegistry();

        distributor = new MockRewardsDistributor();
        registry.setRewardsDistributor(address(distributor));
        pool = new StakingPool(address(stakingToken), address(rewardToken));
        
        vm.prank(address(distributor));
        rewardToken.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testStakingSetup() external {
        assertEq(address(pool.stakingToken()), address(stakingToken));
        assertEq(address(pool.rewardToken()), address(rewardToken));
    }

    function testAddReward() external {
        uint256 amount = 10000e18;
        rewardToken.mint(address(distributor), amount);

        vm.startPrank(address(distributor));
        vm.expectRevert(StakingPool.ZeroAmount.selector);
        pool.addRewards(0);

        uint256 rewardAmount = 1e8;
        vm.expectRevert(abi.encodeWithSelector(StakingPool.InvalidAmount.selector, rewardAmount));
        pool.addRewards(rewardAmount);

        pool.addRewards(amount);
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(address(pool)), amount);
    }
}

contract StakingPoolStaking is StakingPoolTest {

    uint256 public stakeAmount = 1000e18;

    function setUp() public override {
        super.setUp();
        stakingToken.mint(bob, stakeAmount);
        stakingToken.mint(alice, stakeAmount * 3);

        vm.startPrank(bob);
        stakingToken.approve(address(pool), stakeAmount);
        vm.stopPrank(); 
    }

    function testStaking() public {
        vm.startPrank(bob);
        vm.expectRevert(StakingPool.ZeroAmount.selector);
        pool.stake(0);

        pool.stake(stakeAmount);
        vm.stopPrank();

        assertEq(pool.claimable(bob), 0);
        assertEq(stakingToken.balanceOf(bob), 0);
        assertEq(pool.totalStaked(), stakeAmount);
        assertEq(pool.stakingBalance(bob), stakeAmount);
        assertEq(stakingToken.balanceOf(address(pool)), stakeAmount); 
    }

    function testUnstaking() external {
        vm.startPrank(bob);
        pool.stake(stakeAmount);
        pool.unstake(stakeAmount);

        assertEq(pool.totalStaked(), 0);
        assertEq(pool.stakingBalance(bob), 0);
        assertEq(stakingToken.balanceOf(bob), stakeAmount);
        assertEq(stakingToken.balanceOf(address(pool)), 0);

        vm.expectRevert(StakingPool.InsufficientStake.selector);
        pool.unstake(stakeAmount);
        vm.stopPrank();
    }

    /// test claim
    /// - cliamableRewards are 0 if no new rewards have been added after staking
    /// - addRewards -> claimable == rewardAmount
    /// - claimRewards should reset rewards and balance numbers
    function testMultipleClaims() external {
        uint256 rewardAmount = 1000e18;
        rewardToken.mint(address(distributor), rewardAmount);

        vm.startPrank(address(distributor));
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        vm.startPrank(bob);
        pool.stake(stakeAmount);
        vm.stopPrank();

        assertEq(pool.claimable(bob), 0);

        rewardToken.mint(address(distributor), rewardAmount);
        vm.startPrank(address(distributor));
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        assertEq(pool.claimable(bob), rewardAmount);

        vm.startPrank(bob);
        pool.claim();
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(bob), rewardAmount);
        assertEq(pool.claimable(bob), 0);

        uint256 aliceStakeAmount = stakeAmount * 3;
        vm.startPrank(alice);
        stakingToken.approve(address(pool), aliceStakeAmount);
        pool.stake(aliceStakeAmount);
        vm.stopPrank();

        rewardToken.mint(address(distributor), rewardAmount);
        vm.startPrank(address(distributor));
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        
        assertEq(pool.claimable(bob), rewardAmount * 1 / 4);
        assertEq(pool.claimable(alice), rewardAmount * 3 / 4);

        // Alice claims -> claimable(alice) resets.
        // alice's balance matches claimed
        vm.startPrank(alice);
        pool.claim();
        vm.stopPrank();

        assertEq(pool.claimable(alice), 0);
        assertEq(rewardAmount * 3 / 4, rewardToken.balanceOf(alice));

        // alice claiming does not affect bob's balance
        assertEq(pool.claimable(bob), rewardAmount / 4);

        rewardToken.mint(address(distributor), rewardAmount);

        vm.startPrank(address(distributor));
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        // bob can claim old rewards + new
        assertEq(pool.claimable(bob), rewardAmount * 2 / 4);
        // alice can claim new rewards
        assertEq(pool.claimable(alice), rewardAmount * 3 / 4);
    }

    function testRestakeWithRewards() public {
        uint256 rewardAmount = 250e18;

        stakingToken.mint(bob, stakeAmount);
        rewardToken.mint(address(distributor), rewardAmount);

        vm.startPrank(bob);
        pool.stake(stakeAmount);
        vm.stopPrank();

        vm.startPrank(address(distributor));
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        vm.startPrank(bob);
        assertEq(pool.claimable(bob), rewardAmount);

        // stakingToken.mint(bob, stakeAmount);
        stakingToken.approve(address(pool), stakeAmount);
        pool.stake(stakeAmount);
        assertEq(rewardToken.balanceOf(bob), rewardAmount);
        // assertEq(pool.lifetimeClaimed(), rewardAmount);
        // console2.log("***** [lifetimeRewards = %d, accountsCheckPoint = %d]", pool.lifetimeRewards(), pool.accountCheckpoints(bob));
        assertEq(pool.claimable(bob), 0);
        vm.stopPrank();
    }

    // bob stakes x
    // alice stakes x
    // send y rewards
    // unstake 1/2x
    // send y rewards
    function testUnstakeWithRewards() public {
        uint256 rewardAmount = 1000e18;
        stakingToken.mint(bob, stakeAmount * 2);
        stakingToken.mint(alice, stakeAmount * 2);

        // bob stake
        vm.startPrank(bob);
        stakingToken.approve(address(pool), stakeAmount * 2);
        pool.stake(stakeAmount * 2);
        vm.stopPrank();

        // alice stake
        vm.startPrank(alice);
        stakingToken.approve(address(pool), stakeAmount * 2);
        pool.stake(stakeAmount * 2);
        vm.stopPrank();

        // send rewards
        vm.startPrank(address(distributor));
        rewardToken.mint(address(distributor), rewardAmount);
        rewardToken.approve(address(pool), rewardAmount);
        pool.addRewards(rewardAmount);
        vm.stopPrank();
        
        // bob unstake
        vm.startPrank(bob);
        pool.unstake(stakeAmount);
        vm.stopPrank();

        // check rewards claimed and claimable
        assertEq(rewardToken.balanceOf(bob), rewardAmount / 2);
        assertEq(pool.claimable(bob), 0);
        assertEq(pool.claimable(alice), rewardAmount / 2);
        uint256 aliceClaimableBeforeAdd = pool.claimable(alice);

        vm.startPrank(address(distributor));
        rewardToken.mint(address(distributor), rewardAmount);
        rewardToken.approve(address(pool), rewardAmount);
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        // stake pie is currently 1/3 bob, 2/3 alice
        // bob gets 1/3 of new rewards
        // alice gets previous rewards + 2/3 of new rewards
        assertApproxEqAbs(pool.claimable(bob), rewardAmount / 3, 1e18);
        assertApproxEqAbs(pool.claimable(alice), aliceClaimableBeforeAdd + rewardAmount * 2 / 3, 1e18);
    }

    // fuzz testing for staking, unstaking, claiming
}

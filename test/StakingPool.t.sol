// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {StakingPool} from "../contracts/rewards/StakingPool.sol";
import {MockAddressRegistry} from "./mocks/MockAddressRegistry.sol";
import {MockRewardsDistributor} from "./mocks/MockRewardsDistributor.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockCheddaToken} from "./mocks/MockCheddaToken.sol";

contract StakingPoolTest is Test {

    StakingPool internal pool;
    ERC20Mock internal stakingToken;
    MockCheddaToken internal mockChedda;
    MockAddressRegistry internal registry;
    MockRewardsDistributor internal distributor;

    address internal alice;
    address internal bob;
    address internal colin;
    address internal receiver;

    function setUp() public virtual {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        colin = makeAddr("colin");
        receiver = makeAddr("receiver");
        
        stakingToken = new ERC20Mock();
        mockChedda = new MockCheddaToken();
        registry = new MockAddressRegistry();
        registry.setCheddaToken(address(mockChedda));

        distributor = new MockRewardsDistributor();
        registry.setRewardsDistributor(address(distributor));
        pool = new StakingPool(address(registry), address(stakingToken));
        
        vm.prank(address(distributor));
        mockChedda.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testStakingSetup() external view {
        assertEq(address(pool.stakingToken()), address(stakingToken));
        assertEq(address(pool.rewardToken()), address(mockChedda));
    }

    function testAddReward() external {
        uint256 amount = 10000e18;
        mockChedda.mint(address(distributor), amount);

        vm.startPrank(address(distributor));
        vm.expectRevert(StakingPool.ZeroAmount.selector);
        pool.addRewards(0);

        uint256 rewardAmount = 1e8;
        vm.expectRevert(abi.encodeWithSelector(StakingPool.InvalidAmount.selector, rewardAmount));
        pool.addRewards(rewardAmount);

        pool.addRewards(amount);
        vm.stopPrank();

        assertEq(mockChedda.balanceOf(address(pool)), amount);
    }
}

contract StakingPoolStaking is StakingPoolTest {

    uint256 public stakeAmount = 1000e18;
    uint256 public aliceStakeAmount = 3000e18;

    function setUp() public override {
        super.setUp();
        stakingToken.mint(bob, stakeAmount);
        stakingToken.mint(alice, stakeAmount * 3);

        vm.startPrank(bob);
        stakingToken.approve(address(pool), stakeAmount);
        vm.stopPrank(); 
        vm.startPrank(alice);
        stakingToken.approve(address(pool), aliceStakeAmount);
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

    function testMultipleStakes() public {
        vm.startPrank(bob);
        pool.stake(stakeAmount);
        vm.stopPrank();

        vm.startPrank(alice);
        pool.stake(aliceStakeAmount);
        vm.stopPrank();

        assertEq(pool.totalStaked(), stakeAmount + aliceStakeAmount);
        assertEq(pool.stakingBalance(bob), stakeAmount);
        assertEq(pool.stakingBalance(alice), aliceStakeAmount);
        assertEq(stakingToken.balanceOf(address(pool)), stakeAmount + aliceStakeAmount); 
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
        mockChedda.mint(address(distributor), rewardAmount);

        vm.startPrank(address(distributor));
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        vm.startPrank(bob);
        pool.stake(stakeAmount);
        vm.stopPrank();

        assertEq(pool.claimable(bob), 0);

        mockChedda.mint(address(distributor), rewardAmount);
        vm.startPrank(address(distributor));
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        assertEq(pool.claimable(bob), rewardAmount);

        vm.startPrank(bob);
        // uint256 claimed = pool.claim();
        // console2.log("claimed = %d", claimed);

        //====
        uint claimable = pool.claimable(bob);
        (bool success, bytes memory result) = address(pool).delegatecall(abi.encodeWithSignature("claim()"));
        if (success) {
            uint256 claimed = abi.decode(result, (uint256));
            console2.log("****amount = %d, claimed = %d", claimable, claimed);
        } else {
            console2.log("***failure");
        }
        //----
        vm.stopPrank();

        // assertEq(mockChedda.balanceOf(bob), rewardAmount);
        // // assertEq(claimed, rewardAmount);
        // assertEq(pool.claimable(bob), 0);

        // vm.startPrank(alice);
        // stakingToken.approve(address(pool), aliceStakeAmount);
        // pool.stake(aliceStakeAmount);
        // vm.stopPrank();

        // mockChedda.mint(address(distributor), rewardAmount);
        // vm.startPrank(address(distributor));
        // pool.addRewards(rewardAmount);
        // vm.stopPrank();

        
        // assertEq(pool.claimable(bob), rewardAmount * 1 / 4);
        // assertEq(pool.claimable(alice), rewardAmount * 3 / 4);

        // // Alice claims -> claimable(alice) resets.
        // // alice's balance matches claimed
        // vm.startPrank(alice);
        // pool.claim();
        // vm.stopPrank();

        // assertEq(pool.claimable(alice), 0);
        // assertEq(rewardAmount * 3 / 4, mockChedda.balanceOf(alice));

        // // alice claiming does not affect bob's balance
        // assertEq(pool.claimable(bob), rewardAmount / 4);

        // mockChedda.mint(address(distributor), rewardAmount);

        // vm.startPrank(address(distributor));
        // pool.addRewards(rewardAmount);
        // vm.stopPrank();

        // // bob can claim old rewards + new
        // assertEq(pool.claimable(bob), rewardAmount * 2 / 4);
        // // alice can claim new rewards
        // assertEq(pool.claimable(alice), rewardAmount * 3 / 4);
    }

    function testRestakeWithRewards() public {
        uint256 rewardAmount = 250e18;

        stakingToken.mint(bob, stakeAmount);
        mockChedda.mint(address(distributor), rewardAmount);

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
        assertEq(mockChedda.balanceOf(bob), rewardAmount);
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
        mockChedda.mint(address(distributor), rewardAmount);
        mockChedda.approve(address(pool), rewardAmount);
        pool.addRewards(rewardAmount);
        vm.stopPrank();
        
        // bob unstake
        vm.startPrank(bob);
        pool.unstake(stakeAmount);
        vm.stopPrank();

        // check rewards claimed and claimable
        assertEq(mockChedda.balanceOf(bob), rewardAmount / 2);
        assertEq(pool.claimable(bob), 0);
        assertEq(pool.claimable(alice), rewardAmount / 2);
        uint256 aliceClaimableBeforeAdd = pool.claimable(alice);

        vm.startPrank(address(distributor));
        mockChedda.mint(address(distributor), rewardAmount);
        mockChedda.approve(address(pool), rewardAmount);
        pool.addRewards(rewardAmount);
        vm.stopPrank();

        // stake pie is currently 1/3 bob, 2/3 alice
        // bob gets 1/3 of new rewards
        // alice gets previous rewards + 2/3 of new rewards
        assertApproxEqAbs(pool.claimable(bob), rewardAmount / 3, 1e18);
        assertApproxEqAbs(pool.claimable(alice), aliceClaimableBeforeAdd + rewardAmount * 2 / 3, 1e18);
    }

    function testStakers() external {
        stakingToken.mint(bob, stakeAmount);
        stakingToken.mint(alice, stakeAmount);

        assertEq(pool.stakers(), 0);
        // bob stake
        vm.startPrank(bob);
        stakingToken.approve(address(pool), stakeAmount);
        pool.stake(stakeAmount);
        vm.stopPrank();
        assertEq(pool.stakers(), 1);

        // alice stake
        vm.startPrank(alice);
        stakingToken.approve(address(pool), stakeAmount);
        pool.stake(stakeAmount);
        vm.stopPrank(); 
        assertEq(pool.stakers(), 2);

        // full unstake reduces stakers
        vm.startPrank(bob);
        pool.unstake(stakeAmount);
        vm.stopPrank();
        assertEq(pool.stakers(), 1);

        // partial unstake does not reduce stakers
        vm.startPrank(alice);
        pool.unstake(stakeAmount / 2);
        vm.stopPrank();
        assertEq(pool.stakers(), 1);
    }

    // fuzz testing for staking, unstaking, claiming
}

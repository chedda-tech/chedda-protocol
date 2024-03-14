// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LockingGaugeRewardsDistributor} from "../contracts/rewards/LockingGaugeRewardsDistributor.sol";
import {ICheddaPool} from "../contracts/rewards/ICheddaPool.sol";
import {MockCheddaPool} from "./mocks/MockCheddaPool.sol";
import {MockLockingGauge} from "./mocks/MockLockingGauge.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";

contract LockingGaugeRewardsDistributorTest is Test {

    LockingGaugeRewardsDistributor public distributor;
    ERC20Mock public token;
    MockCheddaPool public pool1;
    MockCheddaPool public pool2;
    MockLockingGauge public gauge1;
    MockLockingGauge public gauge2;

    address admin;
    address alice;
    address bob;

    function setUp() external {
        admin = makeAddr("admin");
        alice= makeAddr("bob");
        bob = makeAddr("bob");

        token = new ERC20Mock();
        distributor = new LockingGaugeRewardsDistributor(address(token), admin);
        pool1 = new MockCheddaPool();
        pool2 = new MockCheddaPool();
        gauge1 = new MockLockingGauge();
        gauge2 = new MockLockingGauge();

        // pool1.setGauge(address(gauge1));
        // pool1.setStakingPool(address(pool1));
        // pool2.setGauge(address(gauge2));
        // pool2.setStakingPool(address(pool2));
    }

    function testDistributorSetUp() external view {
        assertEq(address(token), address(distributor.token()));
    }

    function testDistributorRegisterNonAdminFail() external {
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        distributor.registerPool(pool1);
        vm.stopPrank();
    }

    function testDistributorRegisterDuplicateFail() external {
       vm.startPrank(admin);
       distributor.registerPool(pool1);

        vm.expectRevert(
            abi.encodeWithSelector(LockingGaugeRewardsDistributor.AlreadyRegistered.selector, address(pool1))
        );
        distributor.registerPool(pool1);
        vm.stopPrank(); 
    }

    function testDistributorRegisterPool() external {
        vm.startPrank(admin);
        distributor.registerPool(pool1);
        distributor.registerPool(pool2);
        vm.stopPrank();
        assertEq(address(distributor.pools(0)), address(pool1));
        assertEq(address(distributor.pools(1)), address(pool2));
    }

    function testDistributorUnregisterFail() external {
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        distributor.unregisterPool(pool1); 
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(LockingGaugeRewardsDistributor.NotFound.selector, pool1)
        );
        distributor.unregisterPool(pool1);
        vm.stopPrank();
    }

    event PoolUnregistered(address indexed pool);

    function testDistributorUnregisterPool() external {
        vm.startPrank(admin);
        distributor.registerPool(pool1);

        vm.expectEmit(true, false, false, false);
        emit PoolUnregistered(address(pool1));
        distributor.unregisterPool(pool1);
        vm.stopPrank();
    }
    
    function testLockingGaugeDistributeZero() external {
        uint256 distributed = distributor.distribute();
        assertEq(distributed, 0);
    }
    
    function testLockingGaugeDistribute() external {

        uint256 weight1 = 0.8e18;
        uint256 weight2 = 0.2e18;

        RewardsSpy p1Gauge = new RewardsSpy();
        RewardsSpy p2Gauge = new RewardsSpy();
        RewardsSpy p1Stake = new RewardsSpy();
        RewardsSpy p2Stake = new RewardsSpy();

        vm.startPrank(admin);
        distributor.registerPool(pool1);
        distributor.registerPool(pool2);
        p1Gauge.setWeight(weight1);
        p2Gauge.setWeight(weight2);
        vm.stopPrank();

        uint256 mintAmount = 1000e18;
        token.mint(address(distributor), mintAmount);

        pool1.setGauge(address(p1Gauge));
        pool1.setStakingPool(address(p1Stake));
        pool2.setGauge(address(p2Gauge));
        pool2.setStakingPool(address(p2Stake));

        uint256 distributed = distributor.distribute();
        assertEq(distributed, mintAmount);
        assertEq(p1Gauge.rewardAmount(), ud(mintAmount).mul(ud(weight1)).mul(ud(distributor.lockingPortion())).unwrap());
        assertEq(p1Stake.rewardAmount(), ud(mintAmount).mul(ud(weight1)).mul(ud(distributor.stakingPortion())).unwrap());
        assertEq(p2Gauge.rewardAmount(), ud(mintAmount).mul(ud(weight2)).mul(ud(distributor.lockingPortion())).unwrap());
        assertEq(p2Stake.rewardAmount(), ud(mintAmount).mul(ud(weight2)).mul(ud(distributor.stakingPortion())).unwrap());
        assertEq(p1Gauge.rewardAmount() + p1Stake.rewardAmount(), ud(mintAmount).mul(ud(weight1)).unwrap());
        assertEq(p2Gauge.rewardAmount() + p2Stake.rewardAmount(), ud(mintAmount).mul(ud(weight2)).unwrap());
    }

     function testLockingGaugeDistributeFuzz(uint256 mintAmount) external {

        mintAmount = bound(mintAmount, 0, 1_000_000_000e18);
        uint256 weight1 = 0.8e18;
        uint256 weight2 = 0.2e18;

        RewardsSpy p1Gauge = new RewardsSpy();
        RewardsSpy p2Gauge = new RewardsSpy();
        RewardsSpy p1Stake = new RewardsSpy();
        RewardsSpy p2Stake = new RewardsSpy();

        vm.startPrank(admin);
        distributor.registerPool(pool1);
        distributor.registerPool(pool2);
        p1Gauge.setWeight(weight1);
        p2Gauge.setWeight(weight2);
        vm.stopPrank();

        token.mint(address(distributor), mintAmount);

        pool1.setGauge(address(p1Gauge));
        pool1.setStakingPool(address(p1Stake));
        pool2.setGauge(address(p2Gauge));
        pool2.setStakingPool(address(p2Stake));

        uint256 distributed = distributor.distribute();
        assertEq(distributed, mintAmount);
        assertEq(p1Gauge.rewardAmount(), ud(mintAmount).mul(ud(weight1)).mul(ud(distributor.lockingPortion())).unwrap());
        assertEq(p1Stake.rewardAmount(), ud(mintAmount).mul(ud(weight1)).mul(ud(distributor.stakingPortion())).unwrap());
        assertEq(p2Gauge.rewardAmount(), ud(mintAmount).mul(ud(weight2)).mul(ud(distributor.lockingPortion())).unwrap());
        assertEq(p2Stake.rewardAmount(), ud(mintAmount).mul(ud(weight2)).mul(ud(distributor.stakingPortion())).unwrap());

        assertApproxEqAbs(p1Gauge.rewardAmount() + p1Stake.rewardAmount(), ud(mintAmount).mul(ud(weight1)).unwrap(), 1);
        assertApproxEqAbs(p2Gauge.rewardAmount() + p2Stake.rewardAmount(), ud(mintAmount).mul(ud(weight2)).unwrap(), 1);
    }
}

contract RewardsSpy {

    uint256 public rewardAmount;
    uint256 public weight;

    function addRewards(uint256 amount) external {
        rewardAmount = amount;
    }

    function setWeight(uint256 w) external {
        weight = w;
    }
}
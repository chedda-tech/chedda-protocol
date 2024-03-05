// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LockingGaugeRewardsDistributor} from "../contracts/rewards/LockingGaugeRewardsDistributor.sol";
import {ICheddaPool} from "../contracts/rewards/ICheddaPool.sol";
import {MockCheddaPool} from "./mocks/MockCheddaPool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract LockingGaugeRewardsDistributorTest is Test {

    LockingGaugeRewardsDistributor public distributor;
    ERC20Mock public token;
    MockCheddaPool public pool1;
    MockCheddaPool public pool2;

    address admin;
    address alice;
    address bob;

    function setUp() external {
        admin = makeAddr("admin");
        alice= makeAddr("bob");
        bob = makeAddr("bob");

        distributor = new LockingGaugeRewardsDistributor(address(token), admin);
        pool1 = new MockCheddaPool();
        pool2 = new MockCheddaPool();

        pool1.setGauge(makeAddr("pool_1_gauge"));
        pool1.setStakingPool(makeAddr("pool_1_staking"));
        pool2.setGauge(makeAddr("pool_2_gauge"));
        pool2.setStakingPool(makeAddr("pool_2_staking"));

    }

    function testDistributorSetUp() external {
        // assertEq(address(token), address(distributor.token()));
        // distributor.registerPool(pool1);
    }

    function testDistributorRegisterNonAdminFail() external {
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
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
    function testDistributorUnregisterPool() external {
        vm.startPrank(admin);
        distributor.registerPool(pool1);

        // vm.expectEmit(true, false, false, false);
        // emit PoolUnregistered(address(pool1));
        distributor.unregisterPool(pool1);
        vm.stopPrank();
    }

    
    function testDistribute() external {

    }
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {MockLendingPool} from "./mocks/MockLendingPool.sol";
import {LendingPoolLens} from "../contracts/lens/LendingPoolLens.sol";

contract LendingPoolLensTest is Test {

    LendingPoolLens public lens;
    MockLendingPool public pool1;
    MockLendingPool public pool2;
    MockPriceFeed public priceFeed;
    address public owner;
    address public bob;
    MockERC20 public asset1;
    MockERC20 public asset2;
    string public name1 = "pool1";
    string public name2 = "pool2";

    function setUp() external {
        owner = makeAddr("owner");
        bob = makeAddr("bob");

        priceFeed = new MockPriceFeed();
        asset1 = new MockERC20("Asset 1", "AST1", 18, 1_000_000e18);
        asset2 = new MockERC20("Asset 2", "AST2", 18, 1_000_000e18);
        lens = new LendingPoolLens(owner);
        pool1 = new MockLendingPool(name1, address(asset1), address(priceFeed));
        pool2 = new MockLendingPool(name2, address(asset2), address(priceFeed));

        vm.startPrank(owner);
        lens.registerPool(address(pool1), true);
        lens.registerPool(address(pool2), false);
    }

    function testRegisterPool() external {
        vm.startPrank(owner);
        address[] memory registeredPools = lens.registeredPools();
        assertEq(registeredPools.length, 2);
        assertEq(registeredPools[0], address(pool1));
        assertEq(registeredPools[1], address(pool2));
    }

    function testUnregister() external {
        vm.startPrank(owner);
        lens.unregisterPool(address(pool1));
        address[] memory registeredPools = lens.registeredPools();
        assertEq(registeredPools.length, 1);
        assertEq(registeredPools[0], address(pool2));
    }

    function testPoolStats() external {
        uint256 feesPaid = 120e18;
        uint256 tvl = 1_000_000e18;
        pool1.setTvl(tvl);
        pool1.setFeesPaid(feesPaid);
        LendingPoolLens.PoolStats memory stats = lens.getPoolStats(address(pool1));
        assertEq(stats.asset, address(asset1));
        assertEq(stats.characterization, name1);
        assertEq(stats.tvl, tvl);
        assertEq(stats.feesPaid, feesPaid);
        console2.log("Stats asset is %s ", stats.asset);
    }

    function testPoolStatsList() external {
        address[] memory pools = new address[](2);
        pools[0] = address(pool1);
        pools[1] = address(pool2);
        LendingPoolLens.PoolStats[] memory statsList = lens.getPoolStatsList(pools);
        console2.log("stats[0] name is %s", statsList[0].characterization);
        assertEq(statsList[0].characterization, name1);
        assertEq(statsList[1].characterization, name2);
    }

    function testAccountInfoInPool() external {
        uint256 bobSupplied = 120e18;
        uint256 bobHealth = 1.25e18;
        pool1.setAccountHealth(bob, bobHealth);
        pool1.setAccountSupplied(bob, bobSupplied);
        LendingPoolLens.AccountInfo memory info = lens.getPoolAccountInfo(address(pool1), bob);
        console2.log("info.supplied = %d", info.supplied);
        assertEq(info.supplied, bobSupplied);
        assertEq(info.healthFactor, bobHealth);
    }

    function testLendingPoolCollateral() external {}

    function testAggregateStats() external {
        uint256 tvl1 = 100e18;
        uint256 tvl2 = 200e18;
        pool1.setTvl(tvl1);
        pool2.setTvl(tvl2);
        LendingPoolLens.AggregateStats memory stats = lens.getAggregateStats();
        assertEq(stats.tvl, tvl1 + tvl2);
        console2.log("aggregate tvl = %d", stats.tvl);
    }
}
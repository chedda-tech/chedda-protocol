// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {MockLendingPool} from "./mocks/MockLendingPool.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {AddressRegistry} from "../contracts/config/AddressRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract AddressRegistryTest is Test {

    AddressRegistry private registry;
    MockLendingPool public pool1;
    MockLendingPool public pool2;
    MockLendingPool public unregistered;
        MockPriceFeed public priceFeed;
    address public owner;
    address public bob;
    ERC20Mock public asset1;
    ERC20Mock public asset2;
    ERC20Mock public collateral1;
    ERC20Mock public collateral2;
    string public name1 = "pool1";
    string public name2 = "pool2";
    string public name3 = "unregistered";

    function setUp() external {

        owner = makeAddr("owner");
        bob = makeAddr("bob");
        registry = new AddressRegistry(owner);

        priceFeed = new MockPriceFeed(18);
        asset1 = new ERC20Mock();
        asset2 = new ERC20Mock();

        collateral1 = new ERC20Mock();
        collateral2 = new ERC20Mock();
        address[] memory collaterals = new address[](2);
        collaterals[0] = address(collateral1);
        collaterals[1] = address(collateral2);
        pool1 = new MockLendingPool(name1, address(asset1), address(priceFeed), collaterals);
        pool2 = new MockLendingPool(name2, address(asset2), address(priceFeed), collaterals);
        unregistered = new MockLendingPool(name3, address(asset1), address(priceFeed), collaterals);
    }

    function testAddressRegistrySetUp() external view {
        assertEq(registry.cheddaToken(), address(0));
        assertEq(registry.rewardsDistributor(), address(0));
    }

    function testSetCheddaTokenFailOwner() external {
        address chedda = makeAddr("chedda");

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        registry.setCheddaToken(chedda);
        vm.stopPrank();
    }

    function testSetCheddaToken() external {
        address chedda = makeAddr("chedda");

        vm.startPrank(owner);
        registry.setCheddaToken(chedda);
        vm.stopPrank();
        assertEq(registry.cheddaToken(), chedda);
    }

    function testSetRewardsDistributorFail() external {
        address distributor = makeAddr("distributor");
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        registry.setRewardsDistributor(distributor);
        vm.stopPrank();
    }

    function testSetRewardsDistributor() external {
        address distributor = makeAddr("distributor");
        vm.startPrank(owner);
        registry.setRewardsDistributor(distributor);
        vm.stopPrank();
        assertEq(registry.rewardsDistributor(), distributor);
    }

    function testRegisterPoolOwnerFail() external {
        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        registry.registerPool(address(pool1), true);
        vm.stopPrank();
    }

    function testRegisterPool() external {
        vm.startPrank(owner);

        registry.registerPool(address(pool1), true);
        address[] memory registeredPools = registry.registeredPools();
        assertEq(registeredPools[0], address(pool1));
        assertEq(registeredPools.length, 1);

        registry.registerPool(address(pool2), true);
        registeredPools = registry.registeredPools();
        assertEq(registeredPools[1], address(pool2));
        assertEq(registeredPools.length, 2);
        vm.stopPrank();
    }

    function testReregisterPoolFail() external {
        vm.startPrank(owner);

        registry.registerPool(address(pool1), true);
        vm.expectRevert(
            abi.encodeWithSelector(AddressRegistry.AlreadyRegistered.selector, address(pool1))
        );
        registry.registerPool(address(pool1), true);
        vm.stopPrank();
    }

    function testSetActive() external {
        vm.startPrank(owner);

        registry.registerPool(address(pool1), false);
        registry.registerPool(address(pool2), false);

        address[] memory active = registry.activePools();
        assertEq(active.length, 0);

        registry.setActive(address(pool2), true);
        active = registry.activePools();
        assertEq(active.length, 1);

        registry.setActive(address(pool1), false);
        registry.setActive(address(pool2), false);
        active = registry.activePools();
        assertEq(active.length, 0);

        vm.expectRevert(
            abi.encodeWithSelector(AddressRegistry.NotRegistered.selector, address(unregistered))
        );
        registry.setActive(address(unregistered), true);
        vm.stopPrank();
    }

    function testUnregisterPool() external {
        vm.startPrank(owner);
        address[] memory registeredPools = registry.registeredPools();
        assertEq(registeredPools.length, 0);

        registry.registerPool(address(pool1), true);
        registry.registerPool(address(pool2), true);

        registeredPools = registry.registeredPools();
        assertEq(registeredPools.length, 2);
        registry.unregisterPool(address(pool1));
        registry.unregisterPool(address(pool2));
        registeredPools = registry.registeredPools();
        assertEq(registeredPools.length, 0);

        vm.expectRevert(
            abi.encodeWithSelector(AddressRegistry.NotRegistered.selector, address(unregistered))
        );
        registry.unregisterPool(address(unregistered));
        vm.stopPrank();
    }
}

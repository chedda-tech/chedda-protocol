// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "../contracts/config/AddressRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AddressRegistryTest is Test {

    AddressRegistry private registry;
    address private bob;

    function setUp() external {
        registry = new AddressRegistry();
        bob = makeAddr("bob");
    }

    function testSetUp() external {
        assertEq(registry.cheddaToken(), address(0));
        assertEq(registry.rewardsDistributor(), address(0));
    }

    function testSetChddaToken() external {
        address chedda = makeAddr("chedda");
        registry.setCheddaToken(chedda);
        assertEq(registry.cheddaToken(), chedda);
    }

    function testSetRewardsDistributor() external {
        address distributor = makeAddr("distributor");
        registry.setRewardsDistributor(distributor);
        assertEq(registry.rewardsDistributor(), distributor);
    }

    function testPermissions() external {
        vm.startPrank(bob);

        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        registry.setCheddaToken(makeAddr("chedda"));

        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob)
        );
        registry.setRewardsDistributor(makeAddr("distributor"));

        vm.stopPrank();
    }

}
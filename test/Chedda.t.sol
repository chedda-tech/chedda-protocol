// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/tokens/Chedda.sol";

contract CheddaTest is Test {

    Chedda public chedda;

    function setUp() public {
        chedda = new Chedda(address(msg.sender));
    }

    function test_initialSupply() external {
        uint256 initialSupply = chedda.INITIAL_SUPPLY();
        uint256 totalSupply = chedda.totalSupply();
        assertEq(initialSupply, totalSupply);
    }

    function test_emissionPerSecondDecreasesOverTime() external {
        uint256 emissions0 = chedda.emissionPerSecond();
        assertEq(emissions0, 0);

        skip(10 minutes);
        uint256 emissions1 = chedda.emissionPerSecond();
        assertGt(emissions1, 0);

        skip(366 days);
        uint256 emissions2 = chedda.emissionPerSecond();
        assertLt(emissions2, emissions1);

        emit log_named_uint("emissions", emissions0);
    }

    function test_rebaseMintsMoreTokens() public {
        uint256 emissionPerSecond = chedda.emissionPerSecond();
        uint256 initialTotalSupply = chedda.totalSupply();
        chedda.rebase();
        uint256 totalSupplyAfter0Seconds = chedda.totalSupply();
        assertEq(initialTotalSupply, totalSupplyAfter0Seconds);

        skip(1 seconds);
        chedda.rebase();
        uint256 totalSupplyAfter1Second = chedda.totalSupply();
        assertEq(initialTotalSupply + emissionPerSecond, totalSupplyAfter1Second);

        skip(59 seconds);
        chedda.rebase();
        uint256 totalSupplyAfter60Seconds = chedda.totalSupply();
        assertEq(initialTotalSupply + (emissionPerSecond * 60), totalSupplyAfter60Seconds);
    }

    function test_setStakingVault() external {
        address address0 = address(0);
        vm.expectRevert(Chedda.ZeroAddress.selector);
        chedda.setStakingVault(address0);
        address address0x1 = address(0x1);
        chedda.setStakingVault(address0x1);

        address vaultAddress = chedda.stakingVault();
        assertEq(address0x1, vaultAddress);

        vm.prank(address(0x2));
        vm.expectRevert("Ownable: caller is not the owner");
        chedda.setStakingVault(address0x1);
    }

    function test_setGaugeRecipient() external {
        address address0 = address(0);
        vm.expectRevert(Chedda.ZeroAddress.selector);
        chedda.setGaugeRecipient(address0);

        address address0x2 = address(0x2);
        chedda.setGaugeRecipient(address0x2);

        address gaugeRecipient = chedda.gaugeRecipient();
        assertEq(address0x2, gaugeRecipient);

        vm.prank(address(0x2));
        vm.expectRevert("Ownable: caller is not the owner");
        chedda.setGaugeRecipient(address0x2);
    }

    function test_rebaseTokenDistribution() external {
        address stakingVault = address(0x1);
        address gaugeRecipient = address(0x2);
        chedda.setStakingVault(stakingVault);
        chedda.setGaugeRecipient(gaugeRecipient);
        skip(1 seconds);
        chedda.rebase();
        uint256 emissions = chedda.emissionPerSecond();
        UD60x18 stakingShare = chedda.stakingShare();
        uint256 stakingVaultBalance = chedda.balanceOf(stakingVault);
        assertEq(stakingVaultBalance, ud(emissions).mul(stakingShare).unwrap());
        uint256 gaugeRecipientBalance = chedda.balanceOf(gaugeRecipient);
        assertEq(gaugeRecipientBalance, emissions - stakingVaultBalance);
    }
}

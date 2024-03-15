// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import { CheddaToken, Ownable } from "../contracts/tokens/CheddaToken.sol";
import { IRewardsDistributor } from "../contracts/rewards/IRewardsDistributor.sol";

contract CheddaTest is Test {

    CheddaToken public chedda;

    function setUp() external {
        chedda = new CheddaToken(address(msg.sender));
    }

    function testInitialSupply() external view {
        uint256 initialSupply = chedda.INITIAL_SUPPLY();
        uint256 totalSupply = chedda.totalSupply();
        assertEq(initialSupply, totalSupply);
    }

    function testEmissionPerSecondDecreasesOverTime() external {
        skip(10 minutes);
        uint256 emissions1 = chedda.emissionPerSecond();
        assertGt(emissions1, 0);

        skip(366 days);
        uint256 emissions2 = chedda.emissionPerSecond();
        assertLt(emissions2, emissions1);

        // emit log_named_uint("emissions", emissions0);
    }

    function testRebaseMintsMoreTokens() external {
        uint256 emissionPerSecond = chedda.emissionPerSecond();
        console2.log("emissionPerSecond = %d", emissionPerSecond);
        uint256 initialTotalSupply = chedda.totalSupply();
        chedda.rebase();
        uint256 totalSupplyAfter0Seconds = chedda.totalSupply();
        assertEq(initialTotalSupply, totalSupplyAfter0Seconds);
        chedda.setTokenReceiver(address(0x2));

        skip(1 seconds);
        chedda.rebase();
        uint256 totalSupplyAfter1Second = chedda.totalSupply();
        assertEq(initialTotalSupply + emissionPerSecond, totalSupplyAfter1Second);

        skip(59 seconds);
        chedda.rebase();
        uint256 totalSupplyAfter60Seconds = chedda.totalSupply();
        assertEq(initialTotalSupply + (emissionPerSecond * 60), totalSupplyAfter60Seconds);
    }

    function testSetGaugeRecipient() external {
        address address0 = address(0);
        vm.expectRevert(CheddaToken.ZeroAddress.selector);
        chedda.setTokenReceiver(address0);

        address address0x2 = address(0x2);
        chedda.setTokenReceiver(address0x2);

        address tokenReceiver = address(chedda.tokenReceiver());
        assertEq(address0x2, tokenReceiver);

        vm.prank(address(0x2));
        vm.expectRevert();
        vm.expectRevert(Ownable.OwnableUnauthorizedAccount.selector);
        chedda.setTokenReceiver(address0x2);
    }

    function testRebaseTokenDistribution() external {
        // initial rebase amount = 0 if no time has passed.
        uint256 rebaseAmount = chedda.rebase();
        assertEq(rebaseAmount, 0);

        address tokenReceiver = address(0x2);
        chedda.setTokenReceiver(tokenReceiver);
        skip(30 seconds);
        rebaseAmount = chedda.rebase();
        uint256 secondRebaseAmount = chedda.rebase();
        assertGt(rebaseAmount, 0);
        assertEq(secondRebaseAmount, 0);

        // uint256 emissions = chedda.emissionPerSecond();
        // console2.log("second emiisions = %d, rebaseAmount = %d", emissions, rebaseAmount);
        // UD60x18 stakingShare = chedda.stakingShare();
        // uint256 stakingVaultBalance = chedda.balanceOf(stakingVault);
        // assertEq(stakingVaultBalance, ud(emissions).mul(stakingShare).unwrap());
        // uint256 gaugeRecipientBalance = chedda.balanceOf(tokenReceiver);
        // // assertEq(gaugeRecipientBalance, emissions - stakingVaultBalance);
        // console2.log("stakingShare = %d, vaultBalance = %d, gaugeBalance = %d", stakingShare.unwrap(), stakingVaultBalance, gaugeRecipientBalance);
    }

    function testEpoch() external {
        uint256 epoch = chedda.epoch();
        uint256 epochLength = chedda.EPOCH_LENGTH();
        assertEq(epoch, 0);

        skip(epochLength);
        epoch = chedda.epoch();
        assertGt(epoch, 0);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {LendingPool} from "../contracts/pool/LendingPool.sol";
import {MathLib} from "../contracts/library/MathLib.sol";

contract LendingPoolTest is Test {
    // Test can...

    LendingPool public pool;
    MockERC20 public asset;
    MockERC20 public collateral1;
    MockERC20 public collateral2;
    uint256 public assetFactor = 0.9e18;
    uint256 public c1Factor = 0.8e18;
    uint256 public c2Factor = 0.7e18;
    address public poolAddress;
    address public c1Address;
    address public c2Address;
    MockPriceFeed public priceFeed;
    address public bob;
    address public alice;

    string public constant POOL_NAME = "Test Pool";

    using SafeCast for int256;
    using MathLib for uint256;

    function setUp() external {
        asset = new MockERC20("Asset", "AST", 8, 1_000_000e8);
        collateral1 = new MockERC20("Collateral 1", "COL1", 18, 1_000_000e18);
        collateral2 = new MockERC20("Collateral 2", "COL2", 18, 1_000_000e18);
        c1Address = address(collateral1);
        c2Address = address(collateral2);
        bob = makeAddr("bob");
        alice = makeAddr("alice");
        priceFeed = new MockPriceFeed(8);
        priceFeed.setPrice(address(asset), 1e8);
        priceFeed.setPrice(c1Address, 50e8);
        priceFeed.setPrice(c2Address, 25e8);

        LendingPool.CollateralInfo[] memory collateralTypes = new LendingPool.CollateralInfo[](3);
        collateralTypes[0] = LendingPool.CollateralInfo({
            token: address(asset),
            collateralFactor: assetFactor,
            tokenType: LendingPool.TokenType.ERC20
        });
        collateralTypes[1] = LendingPool.CollateralInfo({
            token: c1Address,
            collateralFactor: c1Factor,
            tokenType: LendingPool.TokenType.ERC20
        });
        collateralTypes[2] = LendingPool.CollateralInfo({
            token: c2Address,
            collateralFactor: c2Factor,
            tokenType: LendingPool.TokenType.ERC20
        });

        pool = new LendingPool(POOL_NAME, asset, address(priceFeed), collateralTypes);

        poolAddress = address(pool);
        
        console2.log("Addresses {bob=%b, pool=%s, collateral1=%s}", bob, poolAddress, c1Address);
    }

    function testPoolConfiguration() external {
        assertEq(POOL_NAME, pool.characterization());
        assertEq(address(asset), address(pool.asset()));
        assertEq(address(asset), address(pool.poolAsset()));
        assertEq(address(priceFeed), address(pool.priceFeed()));

        // check collateral
        assertEq(pool.collateralAllowed(address(asset)), true);
        assertEq(pool.collateralAllowed(c1Address), true);
        assertEq(pool.collateralAllowed(c2Address), true);
        assertEq(pool.collateralFactor(c1Address), c1Factor);
        assertEq(pool.collateralFactor(c2Address), c2Factor);
        address[] memory collaterals = pool.collaterals();
        assertEq(collaterals[0], address(asset));
        assertEq(collaterals[1], c1Address);
        assertEq(collaterals[2], c2Address);
    }

    function testGauge() external {
        address gauge = makeAddr("gauge");
        pool.setGauge(gauge);
        assertEq(gauge, address(pool.gauge()));
    }

    function testAddCollateral() external {
        uint256 collateralAmount = 100e18;
        collateral1.transfer(bob, collateralAmount * 2);

        // adding unapproved collateral fails
        address notCollateral = makeAddr("not collateral");
        vm.expectRevert(
            abi.encodeWithSelector(LendingPool.CheddaPool_CollateralNotAllowed.selector, notCollateral)
        );
        pool.addCollateral(notCollateral, collateralAmount);

        // adding asset as collateral fails, must be supplied with collateral option
        vm.expectRevert(LendingPool.CheddaPool_AssetMustBeSupplied.selector);
        pool.addCollateral(address(asset), collateralAmount);

        vm.startPrank(bob);
        vm.expectRevert(); // not approved
        pool.addCollateral(c1Address, collateralAmount);
        uint256 bobBalanceBefore = collateral1.balanceOf(bob);

        collateral1.approve(poolAddress, collateralAmount);

        // zero amount fails
        vm.expectRevert(LendingPool.CheddaPool_ZeroAmount.selector);
        pool.addCollateral(c1Address, 0);

        pool.addCollateral(c1Address, collateralAmount);
        uint256 bobBalanceAfter = collateral1.balanceOf(bob);

        assertEq(pool.tokenCollateralDeposited(c1Address), collateralAmount);
        assertEq(collateral1.balanceOf(poolAddress), collateralAmount);
        assertEq(bobBalanceAfter, bobBalanceBefore - collateralAmount);

        assertEq(pool.accountCollateralAmount(bob, c1Address), collateralAmount);
        console2.log("accountCollateralValue = %d", pool.totalAccountCollateralValue(bob));

        assertEq(pool.totalAccountCollateralValue(bob), 
            _calculateCollateralValue(c1Address, collateralAmount, c1Factor)); 
    }

    function testRemoveCollateral() external {
        uint256 collateralAmount = 100e18;

        collateral1.transfer(bob, collateralAmount * 2);

        vm.startPrank(bob);
        uint256 bobBalanceBefore = collateral1.balanceOf(bob);
        collateral1.approve(poolAddress, collateralAmount);
        pool.addCollateral(c1Address, collateralAmount); 

        // // remove asset collateral fails
        // vm.expectRevert(LendingPool.CheddaPool_AsssetMustBeWithdrawn.selector);
        // pool.removeCollateral(address(asset), collateralAmount);

        // // remove 0 collateral fails
        // vm.expectRevert(LendingPool.CheddaPool_ZeroAmount.selector);
        // pool.removeCollateral(c1Address, collateralAmount);

        // // remove more collateral than deposited fails
        // vm.expectRevert(LendingPool.CheddaPool_InsufficientCollateral.selector);
        // pool.removeCollateral(c1Address, collateralAmount * 2);

        // remove correct amount of collateral succeeds
        pool.removeCollateral(c1Address, collateralAmount);
        uint256 bobBalanceAfter = collateral1.balanceOf(bob);
        assertEq(bobBalanceBefore, bobBalanceAfter);
    }

    function testTake() external {
        uint256 assetDeposits = 1000e8;
        uint256 amountToTake = 100e8;
        uint256 collateralAmount = 10000e18;
        vm.expectRevert(); // collateral not provided
        pool.take(amountToTake);

        collateral1.transfer(bob, collateralAmount);
        asset.transfer(alice, assetDeposits);
        
        vm.startPrank(alice);
        asset.approve(poolAddress, assetDeposits);
        pool.supply(assetDeposits, alice, false);
        vm.stopPrank();

        vm.startPrank(bob);

        // take without depositing collateral
        vm.expectRevert(
            abi.encodeWithSelector(LendingPool.CheddaPool_AccountInsolvent.selector, bob, 0)
        );
        pool.take(amountToTake);

        // deposit collateral and take
        collateral1.approve(poolAddress, collateralAmount);

        pool.addCollateral(c1Address, collateralAmount);
        uint256 shares = pool.take(amountToTake);
        assertEq(amountToTake, asset.balanceOf(bob));
        assertEq(shares, pool.debtToken().balanceOf(bob));

        assertEq(pool.totalAssets(), assetDeposits);
        assertEq(pool.available(), assetDeposits - amountToTake);
        assertEq(pool.borrowed(), amountToTake);
    }

    function testPutShares() external {
        uint256 assetDeposits = 1000e8;
        uint256 amountToTake = 100e8;
        uint256 collateralAmount = 10000e18;
        uint256 excessAssetAmount = 100e8;

        asset.transfer(poolAddress, assetDeposits);
        asset.transfer(bob, excessAssetAmount);
        collateral1.transfer(bob, collateralAmount);

        vm.startPrank(bob);
        collateral1.approve(poolAddress, collateralAmount);
        pool.addCollateral(c1Address, collateralAmount);
        uint256 shares = pool.take(amountToTake);
        
        uint256 assetAmountToRepay = pool.debtToken().convertToAssets(shares);
        console2.log("borrowed=%d, to repay = %d", amountToTake, assetAmountToRepay);
        asset.approve(poolAddress, assetAmountToRepay);
        uint256 bobAssetBalanceBefore = asset.balanceOf(bob);
        pool.putShares(shares);
        uint256 bobAssetBalanceAfter = asset.balanceOf(bob);
        assertEq(0, pool.debtToken().balanceOf(bob));
        assertEq(bobAssetBalanceAfter, bobAssetBalanceBefore - assetAmountToRepay);
    }

    function testPutAmount() external {
        uint256 assetDeposits = 1000e8;
        uint256 amountToTake = 100e8;
        uint256 collateralAmount = 10000e18;
        uint256 excessAssetAmount = 100e8;

        asset.transfer(poolAddress, assetDeposits);
        asset.transfer(bob, excessAssetAmount);
        collateral1.transfer(bob, collateralAmount);

        vm.startPrank(bob);
        collateral1.approve(poolAddress, collateralAmount);
        pool.addCollateral(c1Address, collateralAmount);
        uint256 shares = pool.take(amountToTake);
        
        vm.expectRevert(LendingPool.CheddaPool_ZeroAmount.selector);
        pool.putAmount(0);

        // vm.expectRevert(LendingPool.CheddaPool_Overpayment.selector);
        // pool.putAmount(pool.accountAssetsBorrowed(bob) + 1e18);

        uint256 assetAmountToRepay = amountToTake;
        uint256 sharesToRepay = pool.debtToken().convertToShares(assetAmountToRepay);
        console2.log("borrowed=%d, to repay = %d", amountToTake, assetAmountToRepay);
        asset.approve(poolAddress, assetAmountToRepay);
        uint256 bobAssetBalanceBefore = asset.balanceOf(bob);
        uint256 sharesRepaid = pool.putAmount(amountToTake);
        uint256 bobAssetBalanceAfter = asset.balanceOf(bob);
        assertEq(shares - sharesRepaid, pool.debtToken().balanceOf(bob));

        // repaid at least sharesToRepay, could have repaid more due to time difference between
        // computing convertToShares and putAmount
        assertGe(sharesRepaid, sharesToRepay); 
        assertEq(bobAssetBalanceAfter, bobAssetBalanceBefore - assetAmountToRepay); 
    }

    function testTvlAndState() external {
        uint256 assetAmount = 100e8;

        // assertEq(0, pool.tvl());
        asset.transfer(bob, assetAmount);
        vm.startPrank(bob);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);
        console2.log("^^^tokenCollateralDeposited[%s] = %d", address(asset), pool.tokenCollateralDeposited(address(asset)));
        // uint256 assetValue = ud(assetAmount).mul(ud(priceFeed.readPrice(address(asset), 0).toUint256())).unwrap();
        uint256 assetValue = _calculateAssetValue(address(asset), assetAmount);

        // /// check tvl when supplying as collateral
        console2.log("pool tvl = %d", pool.tvl());
        assertEq(assetValue, pool.tvl());
    }

    function testSupply() external {
        uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);

        vm.startPrank(bob);

        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);

        assertEq(pool.totalAssets(), assetAmount);
        assertEq(pool.available(), assetAmount);
        assertEq(pool.borrowed(), 0);
    }

    function testRedeem() external {
        uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);

        vm.startPrank(bob);

        asset.approve(poolAddress, assetAmount);
        uint256 shares = pool.supply(assetAmount, bob, true);
        assertEq(pool.totalAssets(), assetAmount);
        uint256 redeemed = pool.redeem(shares, bob, bob);
        assertEq(redeemed, assetAmount);
        assertEq(asset.balanceOf(bob), assetAmount);
        assertEq(pool.totalAssets(), 0);
        vm.stopPrank();
    }

    function testRedeemPoolSizeIncrease() external {
        uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);
        asset.transfer(alice, assetAmount * 2);
        // asset.transfer(poolAddress, 100e8);

        // bob supplies
        vm.startPrank(bob);
        asset.approve(poolAddress, assetAmount);
        uint256 bobShares = pool.supply(assetAmount, bob, true);
        vm.stopPrank();

        // alice borrows
        vm.startPrank(alice);
        uint256 borrowAmount = 500e8;
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, alice, true);
        pool.take(borrowAmount);

        // time passes
        // alice pays back with interest
        vm.warp(block.timestamp + 366 days);
        asset.approve(poolAddress, assetAmount*2);
        // uint256 repayment = pool.putShares(debt);
        // console2.log("repayment = %d", repayment);
        vm.stopPrank();
        // bob redeems
        vm.prank(bob);
        uint256 redeemed = pool.redeem(bobShares, bob, bob);
        console2.log("redeemed = %d", redeemed);
        console2.log("totalAssets = %d", pool.totalAssets());

        // check interest earned
        // assertEq(redeemed, assetAmount);
        // assertGt(asset.balanceOf(bob), assetAmount);
        // assertEq(pool.totalAssets(), 0);
    }
    function testWithdraw() external {
        uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);

        vm.startPrank(bob);
        vm.expectRevert(LendingPool.CheddaPool_ZeroShsares.selector);
        pool.withdraw(0, bob, bob);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);
        assertEq(pool.totalAssets(), assetAmount);
        uint256 redeemed = pool.withdraw(assetAmount, bob, bob);
        assertEq(redeemed, assetAmount);
        assertEq(asset.balanceOf(bob), assetAmount);
        assertEq(pool.totalAssets(), 0);
        vm.stopPrank();
    }

    function testUtilization() external {
       uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);

        vm.startPrank(bob); 

        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);

        uint256 utilization = pool.utilization();
        assertEq(utilization, 0);

        uint256 takePercentage = 0.3e18;
        pool.take(ud(takePercentage).mul(ud(assetAmount)).unwrap());
        utilization = pool.utilization();
        assertEq(utilization, takePercentage);
    }

    function testAccountAssetsBorrowed() external {
        uint256 assetAmount = 1000e8;
        uint256 bobBorrowAmount = 600e8;
        uint256 aliceBorrowAmount = 400e8;

        asset.transfer(bob, assetAmount);
        asset.transfer(alice, assetAmount);

        vm.startPrank(bob);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);
        pool.take(bobBorrowAmount);
        assertGe(pool.accountAssetsBorrowed(bob), bobBorrowAmount); // Ge to account for interest
        console2.log("accountAssetBorrowed = %d, borrowAmount = %d", pool.accountAssetsBorrowed(bob), bobBorrowAmount);
        vm.stopPrank();

        vm.startPrank(alice);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, alice, true);
        pool.take(aliceBorrowAmount);
        assertGe(pool.accountAssetsBorrowed(alice), aliceBorrowAmount); //Ge to account for interest
    }

    function testAccountHealth() external {
        uint256 health = pool.accountHealth(bob);
        assertEq(health, type(uint256).max);

        uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);
        asset.transfer(alice, assetAmount);

        vm.startPrank(alice);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, alice, true);
        vm.stopPrank();

        vm.startPrank(bob);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);
        pool.take(assetAmount * 89 / 100);
        health = pool.accountHealth(bob);
        assertGt(health, 1.0e18);
        vm.expectRevert(
            abi.encodeWithSelector(LendingPool.CheddaPool_AccountInsolvent.selector, bob, 999999999677777777)
        );
        pool.take(assetAmount * 1 / 100);
        uint256 newHealth = pool.accountHealth(bob);
        assertEq(health, newHealth);
        console2.log("new health = %d", newHealth);
        // health should be 1.0
    }

    function  testTotalAccountCollateralValue() external {
        uint256 bobC1Amount = 1000e18;
        uint256 bobC2Amount = 2000e18;
        uint256 aliceAssetAmount = 500e8;
        uint256 aliceC2Amount = 500e18;

        collateral1.transfer(bob, bobC1Amount);
        collateral2.transfer(bob, bobC2Amount);
        asset.transfer(alice, aliceAssetAmount);
        collateral2.transfer(alice, aliceC2Amount);

        // bob adds collateral1, collateral2
        vm.startPrank(bob);
        collateral1.approve(poolAddress, bobC1Amount);
        pool.addCollateral(c1Address, bobC1Amount);
        collateral2.approve(poolAddress, bobC2Amount);
        pool.addCollateral(c2Address, bobC2Amount);
        uint256 c1CollateralValue = _calculateCollateralValue(c1Address, bobC1Amount, c1Factor);
        uint256 c2CollateralValue = _calculateCollateralValue(c2Address, bobC2Amount, c2Factor);
        assertEq(pool.totalAccountCollateralValue(bob), c1CollateralValue + c2CollateralValue);
        vm.stopPrank();

        // alice adds asset, collateral2.
        vm.startPrank(alice);
        asset.approve(poolAddress, aliceAssetAmount);
        pool.supply(aliceAssetAmount, alice, true);
        uint256 aliceAssetCollateralValue = _calculateCollateralValue(address(asset), aliceAssetAmount, assetFactor);

        assertEq(pool.totalAccountCollateralValue(alice), aliceAssetCollateralValue);
        collateral2.approve(poolAddress, aliceC2Amount);
        console2.log("aliceCollateralValue = %d", pool.totalAccountCollateralValue(alice));
        // pool.addCollateral(c2Address, aliceC2Amount);
        vm.stopPrank();
    }

    function testAssetBalance() external {
        uint256 amount = 1000e8;
        asset.transfer(bob, amount);

        vm.startPrank(bob);
        asset.approve(poolAddress, amount);
        pool.supply(amount, bob, true);
        assertEq(amount, pool.assetBalance(bob));
        vm.stopPrank();
    }

    function _calculateAssetValue(address assetAddress, uint256 amount) internal view returns (uint256) {
        return ud(
            amount.normalized(MockERC20(assetAddress).decimals(), 18))
            .mul(ud(priceFeed.readPrice(assetAddress, 0).toUint256().normalized(priceFeed.decimals(), 18))).unwrap();
    }

    function _calculateCollateralValue(
        address assetAddress, 
        uint256 amount, 
        uint256 collateralFactor
    ) internal view returns (uint256) {
        return ud(_calculateAssetValue(assetAddress, amount)).mul(ud(collateralFactor)).unwrap();
    }

}

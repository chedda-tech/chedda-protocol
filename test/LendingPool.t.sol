// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {LendingPool} from "../contracts/pool/LendingPool.sol";

contract LendingPoolTest is Test {
    // Test can...

    LendingPool public pool;
    MockERC20 public asset;
    MockERC20 public collateral1;
    MockERC20 public collateral2;
    uint256 public collateral1Factor = 0.9e18;
    uint256 public collateral2Factor = 0.8e18;
    address public poolAddress;
    address public c1Address;
    address public c2Address;
    MockPriceFeed public priceFeed;
    address public bob;
    address public alice;

    string public constant POOL_NAME = "Test Pool";

    using SafeCast for int256;

    function setUp() external {
        asset = new MockERC20("Asset", "AST", 8, 1_000_000e8);
        collateral1 = new MockERC20("Collateral 1", "COL1", 18, 1_000_000e18);
        collateral2 = new MockERC20("Collateral 2", "COL2", 18, 1_000_000e18);
        c1Address = address(collateral1);
        c2Address = address(collateral2);
        priceFeed = new MockPriceFeed();
        priceFeed.setPrice(address(asset), 100e18);
        priceFeed.setPrice(c1Address, 50e18);
        priceFeed.setPrice(c2Address, 25e18);

        LendingPool.CollateralInfo[] memory collateralTypes = new LendingPool.CollateralInfo[](3);
        collateralTypes[0] = LendingPool.CollateralInfo({
            token: address(asset),
            collateralFactor: collateral1Factor,
            tokenType: LendingPool.TokenType.ERC20
        });
        collateralTypes[1] = LendingPool.CollateralInfo({
            token: c1Address,
            collateralFactor: collateral1Factor,
            tokenType: LendingPool.TokenType.ERC20
        });
        collateralTypes[2] = LendingPool.CollateralInfo({
            token: c2Address,
            collateralFactor: collateral2Factor,
            tokenType: LendingPool.TokenType.ERC20
        });

        pool = new LendingPool(POOL_NAME, asset, address(priceFeed), collateralTypes);

        poolAddress = address(pool);
        
        console.log("Addresses {bob=%b, pool=%s, collateral1=%s}", bob, poolAddress, c1Address);
    }

    function testPoolConfiguration() external {
        assertEq(POOL_NAME, pool.characterization());
        assertEq(address(asset), address(pool.asset()));
        assertEq(address(priceFeed), address(pool.priceFeed()));

        // check collateral
        assertEq(pool.collateralAllowed(address(asset)), true);
        assertEq(pool.collateralAllowed(c1Address), true);
        assertEq(pool.collateralAllowed(c2Address), true);
        assertEq(pool.collateralFactor(c1Address), collateral1Factor);
        assertEq(pool.collateralFactor(c2Address), collateral2Factor);
    }

    function testGauge() external {
        address gauge = makeAddr("gauge");
        pool.setGauge(gauge);
        assertEq(gauge, address(pool.gauge()));
    }

    function testAddCollateral() external {
        uint256 collateralAmount = 100e18;
        collateral1.transfer(bob, collateralAmount * 2);

        address notCollateral = makeAddr("not collateral");
        vm.expectRevert(
            abi.encodeWithSelector(LendingPool.CheddaPool_CollateralNotAllowed.selector, notCollateral)
        );
        pool.addCollateral(notCollateral, collateralAmount);

        vm.startPrank(bob);
        vm.expectRevert(); // not approved
        pool.addCollateral(c1Address, collateralAmount);
        uint256 bobBalanceBefore = collateral1.balanceOf(bob);

        collateral1.approve(poolAddress, collateralAmount);

        vm.expectRevert(LendingPool.CheddaPool_ZeroAmount.selector);
        pool.addCollateral(c1Address, 0);

        // vm.expectEmit(true, true, true, true, address(pool));
        // emit LendingPool.CollateralAdded(c1Address, bob, LendingPool.TokenType.ERC20, collateralAmount);

        pool.addCollateral(c1Address, collateralAmount);
        uint256 bobBalanceAfter = collateral1.balanceOf(bob);

        assertEq(pool.tokenCollateralDeposited(c1Address), collateralAmount);
        assertEq(collateral1.balanceOf(poolAddress), collateralAmount);
        assertEq(bobBalanceAfter, bobBalanceBefore - collateralAmount);

        assertEq(pool.accountCollateralAmount(bob, c1Address), collateralAmount);
        console.log("accountCollateralValue = %d", pool.totalAccountCollateralValue(bob));

        // collateralValue = amount * price * collateralFactor
        assertEq(pool.totalAccountCollateralValue(bob), 
            ud(collateralAmount)
            .mul(ud(priceFeed.readPrice(c1Address, 0).toUint256()))
            .mul(ud(pool.collateralFactor(c1Address))).unwrap());
    }

    function testRemoveCollateral() external {
        uint256 collateralAmount = 100e18;

        collateral1.transfer(bob, collateralAmount * 2);

        vm.startPrank(bob);
        uint256 bobBalanceBefore = collateral1.balanceOf(bob);
        collateral1.approve(poolAddress, collateralAmount);

        pool.addCollateral(c1Address, collateralAmount); 
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

        asset.transfer(poolAddress, assetDeposits);
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
        console.log("borrowed=%d, to repay = %d", amountToTake, assetAmountToRepay);
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
        
        uint256 assetAmountToRepay = amountToTake;
        uint256 sharesToRepay = pool.debtToken().convertToShares(assetAmountToRepay);
        console.log("borrowed=%d, to repay = %d", amountToTake, assetAmountToRepay);
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
        uint256 assetAmount = 1000e8;

        // assertEq(0, pool.tvl());
        asset.transfer(bob, assetAmount);
        vm.startPrank(bob);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);
        console.log("^^^tokenCollateralDeposited[%s] = %d", address(asset), pool.tokenCollateralDeposited(address(asset)));
        uint256 assetValue = ud(assetAmount).mul(ud(priceFeed.readPrice(address(asset), 0).toUint256())).unwrap();
        assertEq(assetValue, pool.tvl());
    }

    function testSupply() external {
        uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);

        vm.startPrank(bob);

        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);
    }
}

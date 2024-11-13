// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {DefaultInterestRateModel} from "../contracts/interestrates/DefaultInterestRateModel.sol";
import {LendingPool} from "../contracts/pool/LendingPool.sol";
import {ILendingPool, CollateralInfo, CollateralInfoInit, TokenType} from "../contracts/pool/ILendingPool.sol";
import {MockAddressRegistry} from "./mocks/MockAddressRegistry.sol";
import {MockSteadyInterestRatesModel} from "./mocks/MockSteadyInterestRatesModel.sol";
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
    uint256 public baseFeeBps = 0.1e18;
    uint256 public supplyCap = 1_000_000e18;

    address public poolAddress;
    address public c1Address;
    address public c2Address;
    MockPriceFeed public priceFeed;
    address public admin;
    address public bob;
    address public alice;

    string public constant POOL_NAME = "Test Pool";

    using SafeCast for int256;
    using MathLib for uint256;
    struct InterestRatesParams {
        uint256 baseBorrowRate;
        uint256 rateSlope1;
        uint256 rateSlope2;
        uint256 targetUtilization;
        uint256 reserveFactor;
    }

    function setUp() public virtual {
        asset = new MockERC20("Asset", "AST", 18, 1_000_000e18);
        collateral1 = new MockERC20("Collateral 1", "COL1", 18, 1_000_000e18);
        collateral2 = new MockERC20("Collateral 2", "COL2", 18, 1_000_000e18);
        c1Address = address(collateral1);
        c2Address = address(collateral2);
        admin = makeAddr("admin");
        bob = makeAddr("bob");
        alice = makeAddr("alice");
        priceFeed = new MockPriceFeed(8);
        priceFeed.setPrice(address(asset), 1e8);
        priceFeed.setPrice(c1Address, 50e8);
        priceFeed.setPrice(c2Address, 25e8);

        CollateralInfoInit[] memory collateralTypes = new CollateralInfoInit[](3);
        collateralTypes[0] = CollateralInfoInit({
            token: address(asset),
            info: CollateralInfo({
                ltv: assetFactor,
                liqThreshold: 0.5e18,
                liqPenalty: 0.1e18
            })
        });
        collateralTypes[1] = CollateralInfoInit({
            token: c1Address,
            info: CollateralInfo({
                ltv: c1Factor,
                liqThreshold: 0.5e18,
                liqPenalty: 0.1e18
            })
        });
        collateralTypes[2] = CollateralInfoInit({
            token: c2Address,
            info: CollateralInfo({
                ltv: c2Factor,
                liqThreshold: 0.5e18,
                liqPenalty: 0.1e18
            })
        });

        MockSteadyInterestRatesModel steadyRates = new MockSteadyInterestRatesModel(0.1e18, 0.05e18, 0.1e18);
        MockAddressRegistry registry = new MockAddressRegistry();

        LendingPool.InitParams memory params = LendingPool.InitParams({
            name: POOL_NAME,
            asset: address(asset),
            priceFeed: address(priceFeed),
            interestRatesModel: address(steadyRates),
            owner: admin,
            registry: address(registry),
            reserve: admin,
            reserveFactor: baseFeeBps,
            initialSupplyCap: 1_000_000e18, // decimals must match asset decimals
            stalePriceThreshold: 3600,
            icm: false,
            collaterals: collateralTypes
        });
        pool = new LendingPool(params);

        vm.prank(admin);
        pool.setSupplyCap(supplyCap);
        poolAddress = address(pool);
    }

    function testPoolConfiguration() external view {
        assertEq(POOL_NAME, pool.characterization());
        assertEq(3, pool.version());
        assertEq(address(asset), address(pool.asset()));
        assertEq(address(asset), address(pool.poolAsset()));
        assertEq(address(priceFeed), address(pool.priceFeed()));

        // check collateral
        assertEq(pool.collateralAllowed(address(asset)), true);
        assertEq(pool.collateralAllowed(c1Address), true);
        assertEq(pool.collateralAllowed(c2Address), true);
        assertEq(pool.collateralInfo(c1Address).ltv, c1Factor);
        assertEq(pool.collateralInfo(c2Address).ltv, c2Factor);
        address[] memory collaterals = pool.collaterals();
        assertEq(collaterals[0], address(asset));
        assertEq(collaterals[1], c1Address);
        assertEq(collaterals[2], c2Address);
        assertEq(pool.supplyCap(), supplyCap);
    }

    function testPoolSetGauge() external {
        address gauge = makeAddr("gauge");
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        pool.setGauge(gauge);
        vm.stopPrank();

        vm.startPrank(admin);
        pool.setGauge(gauge);
        vm.stopPrank();
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
        vm.stopPrank();
    }

    function testAddMoreCollateral() external {
        uint256 collateralAmount = 100e18;
        collateral1.transfer(bob, collateralAmount * 2);

        vm.startPrank(bob);
        collateral1.approve(poolAddress, collateralAmount * 2);
        pool.addCollateral(c1Address, collateralAmount);
        assertEq(pool.accountCollateralAmount(bob, c1Address), collateralAmount);

        pool.addCollateral(c1Address, collateralAmount);
        assertEq(pool.accountCollateralAmount(bob, c1Address), collateralAmount * 2);
        vm.stopPrank();
    }

    function testRemovePartCollateral() external {
        uint256 collateralAmount = 100e18;
        collateral1.transfer(bob, collateralAmount * 2);

        vm.startPrank(bob);
        collateral1.approve(poolAddress, collateralAmount * 2);
        pool.addCollateral(c1Address, collateralAmount * 2);
        pool.removeCollateral(c1Address, collateralAmount);
        assertEq(pool.accountCollateralAmount(bob, c1Address), collateralAmount);
        vm.stopPrank();
    }

    function testRemoveCollateral() external {
        uint256 collateralAmount = 100e18;

        collateral1.transfer(bob, collateralAmount * 2);

        vm.startPrank(bob);
        uint256 bobBalanceBefore = collateral1.balanceOf(bob);
        collateral1.approve(poolAddress, collateralAmount);
        pool.addCollateral(c1Address, collateralAmount); 

        // remove asset collateral fails
        vm.expectRevert(LendingPool.CheddaPool_AsssetMustBeWithdrawn.selector);
        pool.removeCollateral(address(asset), collateralAmount);

        // remove 0 collateral fails
        vm.expectRevert(LendingPool.CheddaPool_ZeroAmount.selector);
        pool.removeCollateral(c1Address, 0);

        // // remove more collateral than deposited fails
        vm.expectRevert(
            abi.encodeWithSelector(LendingPool.CheddaPool_InsufficientCollateral.selector,
            bob, c1Address, collateralAmount * 2, collateralAmount)
        );
        pool.removeCollateral(c1Address, collateralAmount * 2);

        // remove correct amount of collateral succeeds
        pool.removeCollateral(c1Address, collateralAmount);
        uint256 bobBalanceAfter = collateral1.balanceOf(bob);
        assertEq(bobBalanceBefore, bobBalanceAfter);
        assertEq(pool.accountCollateralAmount(bob, c1Address), 0);
        vm.stopPrank();
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
        vm.stopPrank();
    }

    function testPutShares() external {
        uint256 assetDeposits = 1000e8;
        uint256 amountToTake = 100e8;
        uint256 collateralAmount = 10000e18;
        uint256 approvalAmount = 200e8;

        asset.transfer(alice, assetDeposits);
        
        vm.startPrank(alice);
        asset.approve(poolAddress, assetDeposits);
        pool.supply(assetDeposits, alice, false);
        vm.stopPrank();

        asset.transfer(bob, approvalAmount);
        collateral1.transfer(bob, collateralAmount);

        vm.startPrank(bob);
        collateral1.approve(poolAddress, collateralAmount);
        pool.addCollateral(c1Address, collateralAmount);
        uint256 shares = pool.take(amountToTake);
        
        uint256 assetAmountToRepay = pool.debtToken().convertToAssets(shares);
        asset.approve(poolAddress, assetAmountToRepay);
        uint256 bobAssetBalanceBefore = asset.balanceOf(bob);
        pool.putShares(shares);
        uint256 bobAssetBalanceAfter = asset.balanceOf(bob);
        assertEq(0, pool.debtToken().balanceOf(bob));
        assertEq(bobAssetBalanceAfter, bobAssetBalanceBefore - assetAmountToRepay);
        vm.stopPrank();
    }

    function testPutAmount() external {
        uint256 assetDeposits = 1000e8;
        uint256 amountToTake = 100e8;
        uint256 collateralAmount = 10000e18;
        uint256 excessAssetAmount = 100e8;

        asset.transfer(alice, assetDeposits);
        
        vm.startPrank(alice);
        asset.approve(poolAddress, assetDeposits);
        pool.supply(assetDeposits, alice, false);
        vm.stopPrank();

        asset.transfer(bob, excessAssetAmount);
        collateral1.transfer(bob, collateralAmount);

        vm.startPrank(bob);
        collateral1.approve(poolAddress, collateralAmount);
        pool.addCollateral(c1Address, collateralAmount);
        uint256 shares = pool.take(amountToTake);
        
        vm.expectRevert(LendingPool.CheddaPool_ZeroAmount.selector);
        pool.putAmount(0);

        uint256 bobAssetsBorrowed = pool.accountAssetsBorrowed(bob);
        vm.expectRevert(LendingPool.CheddaPool_Overpayment.selector);
        pool.putAmount(bobAssetsBorrowed + 100e8);

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
        vm.stopPrank();
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
        vm.stopPrank();
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
        vm.stopPrank();

        // test reverts
        uint256 supplyAmount = supplyCap + 1;
        asset.transfer(bob, supplyAmount);
        vm.startPrank(bob);
        asset.approve(poolAddress, supplyAmount);
        vm.expectRevert(
            abi.encodeWithSelector(LendingPool.CheddaPool_SupplyCapExceeded.selector, supplyCap, assetAmount + supplyAmount)
        );
        pool.supply(supplyAmount, bob, true);
        vm.stopPrank();
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
    
    function testLTVRatio() public {
        // what should the calculation be for max loan to value ratio?
        // LTV = sum(collateralMarketValue * collateralFactor)
        //       ----------------------------------------------
        //              loanValue
        // define Max LTV
                
    }

    function testWithdraw() external {
        uint256 assetAmount = 1000e8;
        asset.transfer(bob, assetAmount);

        vm.startPrank(bob);
        vm.expectRevert(LendingPool.CheddaPool_ZeroShares.selector);
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

    function testFreeAccountCollateral() external {
        uint256 assetAmount = 10000e8;
        uint256 borrowAmount = 4000e8;

        asset.transfer(bob, assetAmount);

        vm.startPrank(bob);
        asset.approve(poolAddress, assetAmount);
        pool.supply(assetAmount, bob, true);

        uint256 cAmount = pool.accountCollateralAmount(bob, address(asset));
        assertEq(assetAmount, cAmount);

        // before borrow
        // total borrow is free
        uint256 freeAssetCollateral = pool.freeAccountCollateralAmount(bob, address(asset));
        assertEq(freeAssetCollateral, assetAmount);

        pool.take(borrowAmount);

        freeAssetCollateral = pool.freeAccountCollateralAmount(bob, address(asset));
        assertGt(freeAssetCollateral, 0);
        assertGt(assetAmount, freeAssetCollateral);

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
        vm.stopPrank();
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
        vm.stopPrank();
    }

    function testAccountHealth() external {
        uint256 health = pool.accountHealth(bob);
        assertEq(health, pool.maxAccountHealth());

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
            abi.encodeWithSelector(LendingPool.CheddaPool_AccountInsolvent.selector, bob, 999999999988888888)
        );
        pool.take(assetAmount * 1 / 100);
        uint256 newHealth = pool.accountHealth(bob);
        assertEq(health, newHealth);
        console2.log("new health = %d", newHealth);
        // health should be 1.0
        vm.stopPrank();
    }

    function testTotalAccountCollateralValue() external {
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

    event PoolState(
        address indexed pool,
        address indexed caller,
        uint256 indexed timestamp,
        uint256 supplied,
        uint256 borrowed,
        uint256 supplyRate,
        uint256 borrowRate
    );

    function testUpdatePoolState() external {
        vm.expectEmit(true, false, false, false);
        emit PoolState(address(pool), address(0), uint(0), uint(0), uint(0), uint(0), uint(0));
        pool.updatePoolState();
    }

    function _calculateAssetValue(address assetAddress, uint256 amount) internal view returns (uint256) {
        (int256 assetPrice, ) = priceFeed.readPrice(assetAddress, 0);
        return ud(
            amount.normalized(MockERC20(assetAddress).decimals(), 18))
            .mul(ud(assetPrice.toUint256().normalized(priceFeed.decimals(), 18))).unwrap();
    }

    function _calculateCollateralValue(
        address assetAddress, 
        uint256 amount, 
        uint256 collateralFactor
    ) internal view returns (uint256) {
        return ud(_calculateAssetValue(assetAddress, amount)).mul(ud(collateralFactor)).unwrap();
    }
}

contract LendingPoolInterestTests is LendingPoolTest {
    uint256 public constant YEAR = 365.25 days;

    function setUp() public override {
        super.setUp();
    }

    function testBorrowInterest() public {
        uint256 assetDeposits = 200000e8;
        uint256 amountToTake = 100000e8;

        asset.transfer(alice, assetDeposits);
        
        vm.startPrank(alice);
        asset.approve(poolAddress, assetDeposits);
        pool.supply(assetDeposits, alice, true);
        uint256 taken = pool.take(amountToTake);
        uint borrowed = pool.accountAssetsBorrowed(alice);
        assertNotEq(borrowed, 0);

        uint256 borrowRate = pool.baseBorrowAPY();
        vm.warp(block.timestamp + YEAR);
        pool.accrueInterest();
        borrowed = pool.accountAssetsBorrowed(alice);

        // check interest including rounding
        assertApproxEqRel(borrowed, taken + (taken * borrowRate / 1e18), 0.0001e18); // within 0.01% delta
        console2.log("[taken = %d, borrowed = %d]", taken, borrowed);
        vm.stopPrank();
    }

  // borrow 100k
    // after 1 year, accumulate 12k interest.
    // supply interest should be 12k * 0.9 (1.0 - 0.1 fee)
    function testSupplyInterest() public {
        uint256 assetDeposits = 200_000e8;
        uint256 amountToTake = 100_000e8;
        asset.transfer(alice, assetDeposits);
        
        vm.startPrank(alice);
        asset.approve(poolAddress, assetDeposits);
        uint256 shares = pool.supply(assetDeposits, alice, true);
        uint256 taken = pool.take(amountToTake);
        uint256 shareValue = pool.convertToAssets(shares);
        console2.log("Before accrue totalAssets now = %d", pool.totalAssets());
        console2.log("Supplied = %d, shares = %d, shareValue = %d", assetDeposits, shares, shareValue);
        console2.log("Before accrue alice assets = %d", pool.convertToAssets(pool.balanceOf(alice)));
        console2.log("Before accrue admin assets = %d", pool.convertToAssets(pool.balanceOf(admin)));

        uint256 supplyRate = pool.baseSupplyAPY();
        vm.warp(block.timestamp + YEAR);
        pool.accrueInterest();
        console2.log("After accrue totalAssets now = %d", pool.totalAssets());
        console2.log("After accrue alice assets = %d", pool.convertToAssets(pool.balanceOf(alice)));
        console2.log("After accrue admin assets = %d", pool.convertToAssets(pool.balanceOf(admin)));
        shareValue = pool.convertToAssets(shares);
        console2.log("After 1 year\nSupplied = %d, shares = %d, shareValue = %d", assetDeposits, shares, shareValue);
        uint256 borrowed = pool.accountAssetsBorrowed(alice);

        // // check interest including rounding
        // assertApproxEqAbs(shareValue, assetDeposits + (assetDeposits * supplyRate / 1e18), 1e1);
        uint zeroPtOnePct = 0.0001e18;
        assertApproxEqRel(pool.totalAssets(), assetDeposits + (assetDeposits * supplyRate / 1e18), zeroPtOnePct);

        // check that alice interest = total interest * (1 - feeBPS)
        assertApproxEqRel(pool.assetBalance(alice), assetDeposits + ((assetDeposits * supplyRate / 1e18) * (1e18 - baseFeeBps)/1e18), zeroPtOnePct);
        //admin interest =  total interest * feeBPS
        // assertApproxEqRel(pool.assetBalance(admin), (assetDeposits * supplyRate / 1e18) * baseFeeBps/1e18, zeroPtOnePct);

        // total interest = alice interest + admin interest
        // assertApproxEqAbs(pool.totalAssets(), pool.assetBalance(alice) + pool.assetBalance(admin), 1);
        console2.log("[0.0001 e18 = %d]", uint(0.0001e18));
        console2.log("[taken = %d, borrowed = %d]", taken, borrowed);
        vm.stopPrank();
    }

    /// fee test should be:
    /// borrow 1000 @ 10% interest and 10% reserveFactor
    /// after 1 year interest earned should be 100, fees collected 100
    function testFeeAccumulation() public {
        uint256 assetDeposits = 20000e8;
        uint256 amountToTake = 1000e8;

        asset.transfer(alice, assetDeposits);
        
        vm.startPrank(alice);
        asset.approve(poolAddress, assetDeposits);
        pool.supply(assetDeposits, alice, true);
        /* uint256 taken =  */ pool.take(amountToTake);
        uint256 borrowedT0 = pool.borrowed();
        vm.warp(block.timestamp + YEAR);
        pool.accrueInterest();
        uint256 totalReserveShares = pool.totalReserveShares();
        uint256 borrowedT1 = pool.borrowed();
        // uint256 balanceAfter = pool.balanceOf(admin);
        console2.log("[borrowedT0 = %d, borrowedT1 = %d, diff = %d]", 
            borrowedT0, borrowedT1, borrowedT1 - borrowedT0);
        console2.log("fees paid = %d, fee in assets = %d", totalReserveShares, pool.convertToAssets(totalReserveShares));
        console2.log("[diff = %d, ,admin balance = %d]", (borrowedT1 - borrowedT0), pool.assetBalance(admin));
        console2.log("[diff*bps = %d, totalSupply = %d, admin balance = %d]", 
            ud(borrowedT1 - borrowedT0).mul(ud(pool.reserveFactor())).unwrap(), pool.totalSupply(), pool.assetBalance(admin));
        assertApproxEqAbs(ud(borrowedT1 - borrowedT0).mul(ud(pool.reserveFactor())).unwrap(), pool.assetBalance(admin), 1);
    }
}

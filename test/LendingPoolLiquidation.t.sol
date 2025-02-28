// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockERC20, ERC20} from "./mocks/MockERC20.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {DefaultInterestRateModel} from "../contracts/interestrates/DefaultInterestRateModel.sol";
import {LendingPool} from "../contracts/pool/LendingPool.sol";
import {ILendingPool, CollateralParams, CollateralInfoInit, TokenType, AccountValue} from "../contracts/pool/ILendingPool.sol";
import {MockAddressRegistry} from "./mocks/MockAddressRegistry.sol";
import {MockSteadyInterestRatesModel} from "./mocks/MockSteadyInterestRatesModel.sol";
import {MathLib} from "../contracts/library/MathLib.sol";
import {IFlashLiquidationCallback} from "../contracts/pool/IFlashLiquidationCallback.sol";

contract LendingPoolLiquidationTests is Test {
    LendingPool public pool;
    MockERC20 public asset;
    MockERC20 public collateral1;
    MockERC20 public collateral2;
    address public c1Address;
    address public c2Address;
    address public supplier;
    address public borrower;
    address public liquidator;
    address public receiver;
    MockPriceFeed public priceFeed;
    uint256 public assetLtv = 0.7e18;
    uint256 public c1Ltv = 0.75e18;
    uint256 public c2Ltv = 0.4e18;
    uint256 public baseFeeBps = 0.1e18;
    uint256 public supplyCap = 1_000_000e18;
    address public admin;
    address public reserve;

    function setUp() external {
         asset = new MockERC20("Asset", "AST", 6, 1_000_000e18);
        collateral1 = new MockERC20("Collateral 1", "COL1", 8, 1_000_000e18);
        collateral2 = new MockERC20("Collateral 2", "COL2", 18, 1_000_000e18);
        c1Address = address(collateral1);
        c2Address = address(collateral2);
        admin = makeAddr("admin");
        reserve = makeAddr("reserve");
        supplier = makeAddr("supplier");
        borrower = makeAddr("borrower");
        liquidator = makeAddr("liquidator");
        receiver = makeAddr("receiver");
        priceFeed = new MockPriceFeed(8);
        priceFeed.setPrice(address(asset), 1e8);
        priceFeed.setPrice(c1Address, 50e8);
        priceFeed.setPrice(c2Address, 25e8);

        CollateralInfoInit[] memory collateralTypes = new CollateralInfoInit[](3);
        collateralTypes[0] = CollateralInfoInit({
            token: address(asset),
            info: CollateralParams({
                ltv: assetLtv,
                lltv: 0.8e18,
                liqPenalty: 0.1e18,
                liqBonus: 0.05e18
            })
        });
        collateralTypes[1] = CollateralInfoInit({
            token: address(collateral1),
            info: CollateralParams({
                ltv: c1Ltv,
                lltv: 0.75e18,
                liqPenalty: 0.1e18,
                liqBonus: 0.08e18
            })
        });
        collateralTypes[2] = CollateralInfoInit({
            token: address(collateral2),
            info: CollateralParams({
                ltv: c2Ltv,
                lltv: 0.75e18,
                liqPenalty: 0.1e18,
                liqBonus: 0.08e18
            })
        });

        MockSteadyInterestRatesModel steadyRates = new MockSteadyInterestRatesModel(0.1e18, 0.05e18, 0.1e18);
        MockAddressRegistry registry = new MockAddressRegistry();

        LendingPool.InitParams memory params = LendingPool.InitParams({
            name: "Test Pool",
            asset: address(asset),
            priceFeed: address(priceFeed),
            interestRatesModel: address(steadyRates),
            owner: admin,
            registry: address(registry),
            reserve: reserve,
            reserveFactor: baseFeeBps,
            initialSupplyCap: supplyCap,
            stalePriceThreshold: 3600,
            collaterals: collateralTypes
        });
        pool = new LendingPool(params);
    }

    function testFlashLiquidationSuccess() external {
        uint256 amountToSupply = 1000e6;
        uint256 amountToBorrow = 500e6;
        uint256 collateral1Amount = 1000e8;
        uint256 repayAmount = 300e6;

        // supply an asset
        deal(address(asset), address(pool), amountToSupply);
        
        // deposit collateral
        deal(address(collateral1), borrower, collateral1Amount);
        vm.startPrank(borrower);
        collateral1.approve(address(pool), collateral1Amount);
        pool.addCollateral(address(collateral1), collateral1Amount);

        // borrow
        pool.take(amountToBorrow);
        vm.stopPrank();

        // collateral price drop
        priceFeed.setPrice(address(collateral1), 0.6e8);

        // liquidate
        LendingPool.LiquidateParams memory params = LendingPool.LiquidateParams({
            borrower: borrower,
            receiver: receiver,
            collateral: address(collateral1),
            repayAmount: repayAmount
        });
        bytes memory data = abi.encode(address(pool), address(asset), repayAmount);
        FlashLiquidationCallbackImpl callback = new FlashLiquidationCallbackImpl();
        vm.prank(admin);
        pool.setCallbackApproved(address(callback), true);
        // asset.transfer(address(callback), repayAmount);
        deal(address(asset), address(callback), repayAmount);

        uint256 assetBalanceBefore = asset.balanceOf(address(pool));
        uint256 accountCollateralBefore = pool.accountCollateralAmount(borrower, address(collateral1));

        vm.startPrank(liquidator);
        uint256 collateralTaken = pool.flashLiquidate(params, address(callback), data);
        vm.stopPrank();

        uint256 assetBalanceAfter = asset.balanceOf(address(pool));
        // (int256 price,) = pool.priceFeed().readPrice(address(asset));

        // check balances
        assertEq(assetBalanceBefore + repayAmount, assetBalanceAfter);
        // check users collateral
        assertEq(pool.accountCollateralAmount(borrower, address(collateral1)) + collateralTaken, accountCollateralBefore);
    }

    // test fails if account healthy
     function testFlashLiquidationFailAccountHealthy() external {
        uint256 amountToSupply = 1000e6;
        uint256 amountToBorrow = 500e6;
        uint256 collateral1Amount = 1000e8;
        uint256 repayAmount = 300e8;

        // supply an asset
        deal(address(asset), address(pool), amountToSupply);

        // deposit collateral
        deal(address(collateral1), borrower, collateral1Amount);

        vm.startPrank(borrower);
        collateral1.approve(address(pool), collateral1Amount);
        pool.addCollateral(address(collateral1), collateral1Amount);

        // borrow
        pool.take(amountToBorrow);
        vm.stopPrank();

        // liquidate
        LendingPool.LiquidateParams memory params = LendingPool.LiquidateParams({
            borrower: borrower,
            receiver: receiver,
            collateral: address(collateral1),
            repayAmount: repayAmount
        });
        bytes memory data = abi.encode(address(pool), address(asset), repayAmount);
        address callback = makeAddr("callback");
        vm.prank(admin);
        pool.setCallbackApproved(address(callback), true);

        deal(address(asset), liquidator, repayAmount);
        uint256 health = pool.accountHealth(borrower);
        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(
            LendingPool.AccountSolvent.selector, 
            borrower, 
            health)
        );
        pool.flashLiquidate(params, address(callback), data);
    }

    // fail if repay amount invalid
    function testFlashLiquidationFailInvalidRepayment() external {
        uint256 amountToSupply = 1000e6;
        uint256 amountToBorrow = 500e6;
        uint256 collateral1Amount = 1000e8;
        uint256 repayAmount0 = 0;
        uint256 repayAmount1 = 600e6;

        // supply an asset
        deal(address(asset), address(pool), amountToSupply);

        // deposit collateral
        deal(address(collateral1), borrower, collateral1Amount);

        vm.startPrank(borrower);
        collateral1.approve(address(pool), collateral1Amount);
        pool.addCollateral(address(collateral1), collateral1Amount);

        // borrow
        pool.take(amountToBorrow);
        vm.stopPrank();

        // collateral price drop
        priceFeed.setPrice(address(collateral1), 0.5e8);

        // check zero repayment
        LendingPool.LiquidateParams memory params0Repayment = LendingPool.LiquidateParams({
            borrower: borrower,
            receiver: receiver,
            collateral: address(collateral1),
            repayAmount: repayAmount0
        });
        bytes memory data = abi.encode(address(pool), address(asset), repayAmount0);
        address callback = makeAddr("callback");
        vm.prank(admin);
        pool.setCallbackApproved(address(callback), true);

        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(
            LendingPool.ZeroAmount.selector));
        pool.flashLiquidate(params0Repayment, address(callback), data);

        // check overpayment
        LendingPool.LiquidateParams memory paramsOverpayment = LendingPool.LiquidateParams({
            borrower: borrower,
            receiver: receiver,
            collateral: address(collateral1),
            repayAmount: repayAmount1
        });
        vm.expectRevert(abi.encodeWithSelector(
            LendingPool.Overpayment.selector));
        pool.flashLiquidate(paramsOverpayment, address(callback), data);
    }

    // test fails if repayAmount not transferred to pool
    function testFlashLiquidationFailPaymentNotReceived() external {
        uint256 amountToSupply = 1000e6;
        uint256 amountToBorrow = 500e6;
        uint256 collateral1Amount = 1000e8;
        uint256 repayAmount = 300e6;

        // supply an asset
        deal(address(asset), address(pool), amountToSupply);

        // deposit collateral
        deal(address(collateral1), borrower, collateral1Amount);

        vm.startPrank(borrower);
        collateral1.approve(address(pool), collateral1Amount);
        pool.addCollateral(address(collateral1), collateral1Amount);

        // borrow
        pool.take(amountToBorrow);
        vm.stopPrank();

        // collateral price drop
        priceFeed.setPrice(address(collateral1), 0.6e8);

        // liquidate
        LendingPool.LiquidateParams memory params = LendingPool.LiquidateParams({
            borrower: borrower,
            receiver: receiver,
            collateral: address(collateral1),
            repayAmount: repayAmount
        });
        bytes memory data = abi.encode(address(pool), address(asset), repayAmount);
        FlashLiquidationCallbackNoTransferImpl callback = new FlashLiquidationCallbackNoTransferImpl();
        vm.prank(admin);
        pool.setCallbackApproved(address(callback), true);

        uint256 assetBalanceBefore = asset.balanceOf(address(pool));
        deal(address(asset), liquidator, repayAmount);

        vm.startPrank(liquidator);
        vm.expectRevert(abi.encodeWithSelector(
            LendingPool.InsufficientAssetBalance.selector, 
            assetBalanceBefore, 
            assetBalanceBefore + repayAmount)
        );
        pool.flashLiquidate(params, address(callback), data);
    }

    function testSpecificLiquidation() external {
        uint256 amountToSupply = 1_000_000;
        uint256 amountToBorrow = 700_000;
        uint256 collateral1Amount = 1000;
        uint256 repayAmount = 700_000;

        priceFeed.setPrice(address(collateral1), 100000e8);
        // supply an asset
        deal(address(asset), address(pool), amountToSupply);
        
        // deposit collateral
        deal(address(collateral1), borrower, collateral1Amount);
        vm.startPrank(borrower);
        collateral1.approve(address(pool), collateral1Amount);
        pool.addCollateral(address(collateral1), collateral1Amount);

        // borrow
        pool.take(amountToBorrow);
        vm.stopPrank();

        // collateral price drop
        priceFeed.setPrice(address(collateral1), 80000e8);
        console2.log("account health = %d", pool.accountHealth(borrower));

        // liquidate
        LendingPool.LiquidateParams memory params = LendingPool.LiquidateParams({
            borrower: borrower,
            receiver: receiver,
            collateral: address(collateral1),
            repayAmount: repayAmount
        });
        bytes memory data = abi.encode(address(pool), address(asset), repayAmount);
        FlashLiquidationCallbackImpl callback = new FlashLiquidationCallbackImpl();
        vm.prank(admin);
        pool.setCallbackApproved(address(callback), true);

        // asset.transfer(address(callback), repayAmount);
        deal(address(asset), address(callback), repayAmount);

        uint256 assetBalanceBefore = asset.balanceOf(address(pool));
        uint256 accountCollateralBefore = pool.accountCollateralAmount(borrower, address(collateral1));

        vm.startPrank(liquidator);
        uint256 collateralTaken = pool.flashLiquidate(params, address(callback), data);
        console2.log("**** collateralTaken = %d", collateralTaken);
        vm.stopPrank();

        uint256 assetBalanceAfter = asset.balanceOf(address(pool));
        // (int256 price,) = pool.priceFeed().readPrice(address(asset));

        // check balances
        assertEq(assetBalanceBefore + repayAmount, assetBalanceAfter);
        // check users collateral
        assertEq(pool.accountCollateralAmount(borrower, address(collateral1)) + collateralTaken, accountCollateralBefore);
    }
}

contract FlashLiquidationCallbackImpl is IFlashLiquidationCallback {

    /// dev expected data is (address, address, uint256)
    function execute(bytes calldata data) external {
        (address poolAddress, address tokenAddress, uint256 tokenAmount) = abi.decode(data, (address, address, uint256));
        console2.log("In Callee: {pool=%s, asset=%s, repayAmount=%d}", poolAddress, tokenAddress, tokenAmount);
        ERC20(tokenAddress).transfer(poolAddress, tokenAmount);
    }
}

contract FlashLiquidationCallbackNoTransferImpl is IFlashLiquidationCallback {

    /// dev expected data is (address, address, uint256)
    function execute(bytes calldata) external {}
}
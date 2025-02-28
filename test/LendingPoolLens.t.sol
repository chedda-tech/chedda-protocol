// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import { UD60x18, ud } from "prb-math/UD60x18.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {MockERC20, ERC20} from "./mocks/MockERC20.sol";
import {MockCheddaToken} from "./mocks/MockCheddaToken.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {MockLendingPool} from "./mocks/MockLendingPool.sol";
import {MockLockingGauge} from "./mocks/MockLockingGauge.sol";
import {MockRewardsDistributor} from "./mocks/MockRewardsDistributor.sol";
import {LendingPoolLens} from "../contracts/lens/LendingPoolLens.sol";
import {AddressRegistry} from "../contracts/config/AddressRegistry.sol";

contract LendingPoolLensTest is Test {

    LendingPoolLens public lens;
    AddressRegistry public registry;
    MockCheddaToken public chedda;
    MockLendingPool public pool1;
    MockLendingPool public pool2;
    MockLendingPool public unregistered;
    MockPriceFeed public priceFeed;
    address public owner;
    address public bob;
    MockERC20 public asset1;
    MockERC20 public asset2;
    MockERC20 public collateral1;
    MockERC20 public collateral2;
    string public name1 = "pool1";
    string public name2 = "pool2";
    string public name3 = "unregistered";

    function setUp() external {
        owner = makeAddr("owner");
        bob = makeAddr("bob");

        chedda = new MockCheddaToken();
        registry = new AddressRegistry(owner);
        MockRewardsDistributor distributor = new MockRewardsDistributor();

        priceFeed = new MockPriceFeed(18);
        asset1 = new MockERC20("Asset 1", "AST1", 18, 1_000_000e18);
        asset2 = new MockERC20("Asset 2", "AST2", 18, 1_000_000e18);

        collateral1 = new MockERC20("Collateral 1", "C1", 18, 1_000_000e18);
        collateral2 = new MockERC20("Collateral 2", "C2", 18, 1_000_000e18);

        priceFeed.setPrice(address(asset1), 1.8e8);
        priceFeed.setPrice(address(asset2), 1.0e8);
        priceFeed.setPrice(address(collateral1), 100e8);
        priceFeed.setPrice(address(collateral2), 120e8);
        priceFeed.setPrice(address(chedda), 10e8);
        lens = new LendingPoolLens(address(registry));
        address[] memory collaterals = new address[](2);//[address(0x1), address(0x2)];
        collaterals[0] = address(collateral1);
        collaterals[1] = address(collateral2);
        pool1 = new MockLendingPool(name1, address(asset1), address(priceFeed), collaterals);
        pool2 = new MockLendingPool(name2, address(asset2), address(priceFeed), collaterals);
        pool1.setGauge(address(new MockLockingGauge()));
        pool2.setGauge(address(new MockLockingGauge()));
        unregistered = new MockLendingPool(name3, address(asset1), address(priceFeed), collaterals);

        vm.startPrank(owner);
        registry.setCheddaToken(address(chedda));
        registry.setCheddaPriceOracle(address(priceFeed));
        registry.registerPool(address(pool1), true);
        registry.registerPool(address(pool2), true);
        registry.setRewardsDistributor(address(distributor));
        vm.stopPrank();
    }

    function testPoolSetup() external view {
        assertEq(lens.version(), 2);
        assertEq(lens.registeredPools().length, 2);
        assertEq(lens.activePools().length, 2);
    }

    function testEmptyPoolStats() external view {
       LendingPoolLens.PoolStats memory stats = lens.getPoolStats(address(pool1));
        assertEq(stats.pool, address(pool1)); 
    }

    function testSinglePoolStats() external {
        uint256 totalReserveShares = 120e18;
        uint256 tvl = 1_000_000e18;
        pool1.setTvl(tvl);
        pool1.setReserveShares(totalReserveShares);
        LendingPoolLens.PoolStats memory stats = lens.getPoolStats(address(pool1));
        assertEq(stats.pool, address(pool1));
        assertEq(stats.asset, address(asset1));
        assertEq(stats.characterization, name1);
        // assertEq(stats.tvl, tvl);
        assertEq(stats.totalReserveShares, totalReserveShares);
        console2.log("Stats asset is %s ", stats.asset);

        vm.expectRevert(
            abi.encodeWithSelector(LendingPoolLens.NotRegistered.selector, address(unregistered))
        );
        lens.getPoolStats(address(unregistered));
    }

    function testPoolStatsList() external {
        address[] memory pools = new address[](2);
        pools[0] = address(pool1);
        pools[1] = address(pool2);
        LendingPoolLens.PoolStats[] memory statsList = lens.getPoolStatsList(pools);
        console2.log("stats[0] name is %s", statsList[0].characterization);
        assertEq(statsList[0].characterization, name1);
        assertEq(statsList[1].characterization, name2);

        address[] memory unregisteredPools = new address[](1);
        unregisteredPools[0] = address(unregistered);
        vm.expectRevert(
            abi.encodeWithSelector(LendingPoolLens.NotRegistered.selector, address(unregistered))
        );
        lens.getPoolStatsList(unregisteredPools);
    }

    function testAccountInfoInPool() external {
        uint256 bobSupplied = 120e18;
        uint256 bobHealth = 1.25e18;
        pool1.setAccountSupplied(bob, bobSupplied);
        pool1.setAccountHealth(bob, bobHealth);
        LendingPoolLens.AccountInfo memory info = lens.getPoolAccountInfo(address(pool1), bob);
        assertEq(info.supplied, bobSupplied);
        assertEq(info.healthFactor, bobHealth);
        assertEq(info.decimals, pool1.poolAsset().decimals());
        assertEq(info.walletAssetBalance, ERC20(pool1.poolAsset()).balanceOf(bob));
    }

    function testPoolCollateral() external view {
        // deposit asset as colateral

        // deposit collateral 1 + 2
        // checkt
        LendingPoolLens.PoolCollateralInfo[] memory collateralInfo = lens.getPoolCollateral(address(pool1));
        assertEq(collateralInfo[0].collateral, address(collateral1));
        assertEq(collateralInfo[0].decimals, collateral1.decimals());
        assertEq(collateralInfo[0].amountDeposited, pool1.tokenCollateralDeposited(address(collateral1)));
        assertEq(collateralInfo[0].value, 
        pool1.tokenMarketValue(address(collateral1), pool1.tokenCollateralDeposited(address(collateral1))));
        assertEq(collateralInfo[0].ltv, pool1.collateralInfo(address(collateral1)).ltv);

        assertEq(collateralInfo[1].collateral, address(collateral2));
        assertEq(collateralInfo[1].decimals, collateral2.decimals());
        assertEq(collateralInfo[1].amountDeposited, pool1.tokenCollateralDeposited(address(collateral2)));
        assertEq(collateralInfo[1].value, 
        pool1.tokenMarketValue(address(collateral2), pool1.tokenCollateralDeposited(address(collateral2))));
        assertEq(collateralInfo[1].ltv, pool1.collateralInfo(address(collateral2)).ltv);
    }

    function testPoolMarketInfo() external view {
        LendingPoolLens.MarketInfo memory marketInfo = lens.getMarketInfo(address(pool1));
        (int256 assetPrice, ) = pool1.priceFeed().readPrice(address(pool1.poolAsset()));
        assertEq(marketInfo.oraclePrice, assetPrice);
        assertEq(marketInfo.oraclePriceDecimals, pool1.priceFeed().decimals());
        assertEq(marketInfo.supplyCap, pool1.supplyCap());
        assertEq(marketInfo.utilization, pool1.utilization());
        assertEq(marketInfo.liquidity, pool1.available());
    }

    function testAggregateStats() external {
        uint256 tvl1 = 100e18;
        uint256 tvl2 = 200e18;
        pool1.setTvl(tvl1);
        pool2.setTvl(tvl2);
        LendingPoolLens.AggregateStats memory stats = lens.getAggregateStats(false);
        assertEq(stats.tvl, tvl1 + tvl2);
        assertEq(stats.numberOfVaults, 2);
        console2.log("aggregate tvl = %d", stats.tvl);
    }

    function testPoolDailyRewards() external {
        
    }
}

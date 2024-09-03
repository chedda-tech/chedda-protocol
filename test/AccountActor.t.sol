// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {AccountActor} from "../contracts/lens/AccountActor.sol";
import {ICheddaPool} from "../contracts/rewards/ICheddaPool.sol";
import {ILockingGauge} from "../contracts/rewards/ILockingGauge.sol";
import {IStakingPool} from "../contracts/rewards/IStakingPool.sol";
import {MockAddressRegistry} from "./mocks/MockAddressRegistry.sol";
import {MockLendingPool} from "./mocks/MockLendingPool.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Lock, LockTime} from "../contracts/rewards/ILockingGauge.sol";

contract AccountActorTest is Test {

    AccountActor public actor;
    AccountActorRegistrySpy public registry;
    address public account;

    function setUp() public virtual {
        account = makeAddr("account");
        registry = new AccountActorRegistrySpy();
        actor = new AccountActor(address(registry));
        registry.setAccountActor(address(actor));
    }

    function testAccountActorSetup() public view {
        assertEq(address(registry), address(actor.registry()));
    }
}

contract AccountActorClaimTests is AccountActorTest {
    MockClaimable stakingPool1;
    MockClaimable lockingGauge1;
    MockClaimable stakingPool2;
    MockClaimable lockingGauge2;

    function setUp() public override {
        super.setUp();
        account = makeAddr("account");
        registry = new AccountActorRegistrySpy();
        actor = new AccountActor(address(registry));
        stakingPool1 = new MockClaimable();
        lockingGauge1 = new MockClaimable();
        stakingPool2 = new MockClaimable();
        lockingGauge2 = new MockClaimable();

        MockICheddaPool pool1 = new MockICheddaPool(
            address(stakingPool1), address(lockingGauge1)
        );
        MockICheddaPool pool2 = new MockICheddaPool(
            address(stakingPool2), address(lockingGauge2)
        );
        registry.registerPool(address(pool1));
        registry.registerPool(address(pool2));
    } 

    function testAllClaimableRewards() public {
        uint256 stake1 = 10e18;
        uint256 stake2 = 25e18;
        uint256 lock1 = 15e18;
        uint256 lock2 = 30e18;

        // set rewards 1 and 2
        stakingPool1.addRewards(stake1);
        stakingPool2.addRewards(stake2);
        lockingGauge1.addRewards(lock1);
        lockingGauge2.addRewards(lock2);

        (uint256 stakingRewards, uint256 lockingRewards) = actor.allClaimableRewards(account);
        assertEq(stakingRewards, stake1 + stake2);
        assertEq(lockingRewards, lock1 + lock2);
    }

    function testClaimAllRewardsNotAuthorized() public {
        address testAccount = makeAddr("test");
        vm.startPrank(testAccount);
        vm.expectRevert(
            abi.encodeWithSelector(AccountActor.NotAuthorized.selector, testAccount)
        );
        actor.claimAllRewards(account);
        vm.stopPrank();
    }

    function testClaimAllRewards() public {
        vm.startPrank(account);
        uint256 claimed = actor.claimAllRewards(account);
        assertEq(claimed, 0);

        uint256 stake1 = 10e18;
        uint256 stake2 = 25e18;
        uint256 lock1 = 15e18;
        uint256 lock2 = 30e18;

        // set rewards 1 and 2
        stakingPool1.addRewards(stake1);
        stakingPool2.addRewards(stake2);
        lockingGauge1.addRewards(lock1);
        lockingGauge2.addRewards(lock2);

        claimed = actor.claimAllRewards(account);
        assertEq(claimed, stake1 + stake2 + lock1 + lock2);
        vm.stopPrank();
    }
}

contract AccountActorPositionTests is AccountActorTest {
    MockLendingPool pool;

    function setUp() public override {
        super.setUp();
        MockPriceFeed priceFeed = new MockPriceFeed(8);
        MockERC20 token = new MockERC20("Mock", "MOCK", 18, 1_000_000e18);
        MockERC20 collateral = new MockERC20("Coll", "COLL", 18, 1_000_000e18);
        address[] memory collaterals = new address[](1);
        collaterals[0] = address(collateral);
        pool = new MockLendingPool(
            "mPool",
            address(token),
            address(priceFeed),
            collaterals
        );
    }

    function testAccountActorGetPosition() public {
        MockClaimable claimable = new MockClaimable();
        pool.setStakingPool(address(claimable));
        pool.setGauge(address(claimable));

        Lock memory lock = Lock({
            amount: 777e18,
            timeWeighted: 999e18,
            expiry: block.timestamp + 1_000_000,
            rewardDebt: 10,
            lockTime: LockTime.thirtyDays
        });
        claimable.setStakingBalance(account, 999e18);
        claimable.setLock(account, lock);
        pool.setAccountCollateralValue(account, 123e18);
        pool.setAccountHealth(account, 1.25e18);

        AccountActor.Position memory position = actor.getPosition(account, address(pool));

        assertEq(position.account, account);
        assertEq(position.asset, address(pool.poolAsset()));
        assertEq(position.healthFactor, pool.accountHealth(account));
        assertEq(position.collateralValue, pool.totalAccountCollateralValue(account));
        assertEq(position.staked, claimable.stakingBalance(account));
        assertEq(position.locked, claimable.getLock(account).amount);
        assertNotEq(position.exposure, 0);
    }

    function testAcountActorGetNoPositions() public view {
        AccountActor.Position[] memory positions = actor.allPositions(account, false);
        assertEq(positions.length, 0);
    }

    function testAccountActorGetAllPositions() public {
        registry = new AccountActorRegistrySpy();
        actor = new AccountActor(address(registry));
        MockClaimable stakingPool = new MockClaimable();
        MockClaimable lockingGauge = new MockClaimable();

        pool.setStakingPool(address(stakingPool));
        pool.setGauge(address(lockingGauge));
        registry.registerPool(address(pool));
        
        AccountActor.Position[] memory positions = actor.allPositions(account, false);
        assertEq(positions.length, 1);
        assertEq(positions[0].exposure, 0);
    }
}

contract AccountActorSummaryTest is AccountActorTest {
    MockLendingPool pool;

    function setUp() public override {
        super.setUp();
        MockPriceFeed priceFeed = new MockPriceFeed(8);
        MockERC20 token = new MockERC20("Mock", "MOCK", 18, 1_000_000e18);
        MockERC20 mockChedda = new MockERC20("Mock", "MOCK", 18, 1_000_000e18);
        MockERC20 collateral = new MockERC20("Coll", "COLL", 18, 1_000_000e18);
        address[] memory collaterals = new address[](1);
        collaterals[0] = address(collateral);
        pool = new MockLendingPool(
            "mPool",
            address(token),
            address(priceFeed),
            collaterals
        );
        MockClaimable stakingPool = new MockClaimable();
        MockClaimable lockingGauge = new MockClaimable();

        pool.setStakingPool(address(stakingPool));
        pool.setGauge(address(lockingGauge));
        priceFeed.setPrice(address(mockChedda), 2.55e8);
        registry.setCheddaToken(address(mockChedda));
        registry.registerPool(address(pool));
        registry.setCheddaPriceOracle(address(priceFeed));
    }

    function testAccountActorSummary() public view {
        AccountActor.AccountSummary memory summary = actor.accountSummary(account);
        assertEq(summary.netValue, 0);
    }
}
/// @dev AddressRegistry spy
contract AccountActorRegistrySpy is MockAddressRegistry {
    address[] private _pools;

    function registerPool(address pool) public {
        _pools.push(pool);
    }

    function registeredPools() external override view returns (address[] memory) {
        return _pools;
    }    

    function activePools() external override view returns (address[] memory) {
        return _pools;
    }    
}

contract MockICheddaPool is ICheddaPool {
    IStakingPool private _stakingPool;
    ILockingGauge private _lockingGauge;

    constructor(address staking, address locking) {
        _stakingPool = IStakingPool(staking);
        _lockingGauge = ILockingGauge(locking);
    }

    function gauge() external view returns (ILockingGauge) {
        return _lockingGauge;
    }

    function stakingPool() external view returns (IStakingPool) {
        return _stakingPool;
    }

    function setStakingPool(address sPool) external {
        _stakingPool = IStakingPool(sPool);
    }

    function setGauge(address g) external {
        _lockingGauge = ILockingGauge(g);
    }
}

contract MockClaimable is IStakingPool {

    uint256 private _totalClaimable;
    mapping (address => uint256) private _stakingBalances;
    mapping (address => Lock) private _locks;

    function setStakingBalance(address account, uint256 amount) external {
        _stakingBalances[account] = amount;
    }
    function stake(uint256 amount) external pure returns (uint256) { 
        return amount;
    }

    function unstake(uint256 amount) external pure returns (uint256) {
        return amount;
    }

    function claim() external returns (uint256) {
        return claimFor(msg.sender);
    }

    function claimFor(address) public returns (uint256) {
        uint256 toClaim = _totalClaimable;
        _totalClaimable = 0;
        return toClaim;
    }

    function claimable(address) external view returns (uint256) {
        return _totalClaimable;
    }

    function stakingBalance(address account) external view returns (uint256) {
        return _stakingBalances[account];
    }

    function setLock(address account, Lock memory lock) external {
        _locks[account] = lock;
    }

    function getLock(address account) external view returns (Lock memory) {
        return _locks[account];
    }

    function addRewards(uint256 amount) external {
        _totalClaimable += amount;
    }
}

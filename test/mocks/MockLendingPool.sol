// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { IPriceFeed } from "../../contracts/oracle/IPriceFeed.sol";
import { ILendingPool, CollateralParams, AccountValue } from "../../contracts/pool/ILendingPool.sol";
import { IInterestRateModel } from "../../contracts/interestrates/IInterestRateModel.sol";
import { DebtToken } from "../../contracts/tokens/DebtToken.sol";
import { MockERC20 } from "./MockERC20.sol";
import {ICheddaPool} from "../../contracts/rewards/ICheddaPool.sol";
import {ILockingGauge} from "../../contracts/rewards/ILockingGauge.sol";
import {IStakingPool} from "../../contracts/rewards/IStakingPool.sol";

contract MockLendingPool is ILendingPool, ICheddaPool {

    DebtToken public debtToken;
    MockERC20 public asset;
    IPriceFeed public priceFeed;
    string public characterization;

    uint256 private _tvl;
    uint256 private _reserveShares;
    uint256 public supplyCap = 1_000_000e18;
    address private _stakingPool;
    address private _gauge;
    address[] private _collaterals;
    mapping (address => uint) private _accountSupplied;
    mapping (address => uint) private _accountBorrowed;
    mapping (address => uint) private _accountCollateralValue;
    mapping (address => uint) private _accountCollateralAmount;
    mapping (address => uint) private _accountHealth;

    constructor(string memory _characterization, address _asset, address _priceFeed, address[] memory c) {
        asset = MockERC20(_asset);
        debtToken = new DebtToken(asset, address(this));
        priceFeed = IPriceFeed(_priceFeed);
        characterization = _characterization;
        _collaterals = c;
    }
    
    ///////////////////////////////////////////////////////////////////////////
    ///             Mock setters
    ///////////////////////////////////////////////////////////////////////////
    function setTvl(uint256 t) external {
        _tvl = t;
    }

    function setGauge(address g) external {
        _gauge = g;
    }

    function setStakingPool(address s) external {
        _stakingPool = s;
    }

    function setReserveShares(uint256 fees) external {
        _reserveShares = fees;
    }

    function setAccountSupplied(address account, uint256 amount) external {
        _accountSupplied[account] = amount;
    }

    function setAccountBorrowed(address account, uint256 amount) external {
        _accountBorrowed[account] = amount;
    }

    function setAccountHealth(address account, uint256 health) external {
        _accountHealth[account] = health;
    }

    function setAccountCollateralValue(address account, uint256 value) external {
        _accountCollateralValue[account] = value;
    }

    function setAccountCollateralAmount(address account, uint256 amount) external {
        _accountCollateralValue[account] = amount;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///             ILendingPool interface implementation
    ///////////////////////////////////////////////////////////////////////////

    function poolAsset() external view returns (ERC20) {
        return asset;
    }

    function supplied() external pure returns (uint256) {
        return 1000e18;
    }

    function borrowed() external pure returns (uint256) {
        return 100e18;
    }
    function available() external pure returns (uint256) {
        return 0;
    }
    function baseSupplyAPY() external pure returns (uint256) {
        return 5.0e18;
    }

    function baseBorrowAPY() external pure returns (uint256) {
        return 7.5e18;
    }

    function utilization() external pure returns (uint256) {
        return 0.85e18;
    }

    function tvl(bool) external view returns (uint256) {
        return _tvl;
    }

    function convertToAssets(uint256) external pure returns (uint256) {
        return 0;
    }

    function totalReserveShares() external view returns (uint256) {
        return _reserveShares;
    }

    function interestRatesModel() external pure returns (IInterestRateModel) {
        return IInterestRateModel(address(0));
    }

    function collaterals() external view returns (address [] memory) {
        return _collaterals;
    }

    function collateralFactor(address) external pure returns (uint256) {
        return 0.85e18;
    }

    function tokenCollateralDeposited(address) external pure returns (uint256) {
        return 120e18;
    }

    function accountHealth(address account) external view returns (uint256) {
        return _accountHealth[account];
    }

    function assetBalance(address account) external view returns (uint256) {
        return _accountSupplied[account];
    }

    function assetsBorrowed(address account) external view returns (uint256) {
        return _accountBorrowed[account];
    }

    function tokenLiquidationValue(address account) external view returns (uint256) {
        return _accountCollateralValue[account];
    }

    function accountCollateralAmount(address account, address) external view returns (uint256) {
        return _accountCollateralAmount[account];
    }

    function tokenLoanValue(address, uint256) external pure returns (uint256) {
        return 100e18;
    }

    function tokenMarketValue(address, uint256) external pure returns (uint256) {
        return 250e18;
    }

    function tokenLiquidationValue(address, uint256) external pure returns (uint256) {
        return 200e18;
    }

    function totalAccountCollateralValue( address, AccountValue) public pure returns (uint256) {
        return 1000e18;
    }

    function stakingPool() external view returns (IStakingPool) {
        return IStakingPool(_stakingPool);
    }

    function gauge() external view returns (ILockingGauge) {
        return ILockingGauge(_gauge);
    }

    function recapitalize() external pure returns (uint256) {
        return 0;
    }

    function collateralInfo(address) external pure returns (CollateralParams memory) {
        return CollateralParams({
            ltv: 0,
            lltv: 0,
            liqPenalty: 0,
            liqBonus: 0.1e18
        });
    }
}
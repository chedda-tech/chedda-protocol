// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { IPriceFeed } from "../../contracts/oracle/IPriceFeed.sol";
import { ILendingPool } from "../../contracts/pool/ILendingPool.sol";
import { IInterestRatesModel } from "../../contracts/pool/IInterestRatesModel.sol";
import { ILiquidityGauge } from "../../contracts/gauge/ILiquidityGauge.sol";
import { DebtToken } from "../../contracts/tokens/DebtToken.sol";
import { MockERC20 } from "./MockERC20.sol";

contract MockLendingPool is ILendingPool {

    DebtToken public debtToken;
    MockERC20 public asset;
    IPriceFeed public priceFeed;
    string public characterization;

    uint256 private _tvl;
    uint256 private _feesPaid;
    uint256 public supplyCap = 1_000_000e18;
    address[] private _collaterals;
    mapping (address => uint) private _accountSupplied;
    mapping (address => uint) private _accountBorrowed;
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

    function setFeesPaid(uint256 fees) external {
        _feesPaid = fees;
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

    function setTokenCollateralDeposited(address token, uint256 amount) external {
        
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

    function tvl() external view returns (uint256) {
        return _tvl;
    }

    function feesPaid() external view returns (uint256) {
        return _feesPaid;
    }

    function gauge() external pure returns (ILiquidityGauge) {
        return ILiquidityGauge(address(0));
    }

    function interestRatesModel() external pure returns (IInterestRatesModel) {
        return IInterestRatesModel(address(0));
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

    function accountAssetsBorrowed(address account) external view returns (uint256) {
        return _accountBorrowed[account];
    }

    function totalAccountCollateralValue(address) external pure returns (uint256) {
        return 500e18;
    }

    function accountCollateralAmount(address, address) external pure returns (uint256) {
        return 200e18;
    }

    function getTokenCollateralValue(address, uint256) external pure returns (uint256) {
        return 100e18;
    }

    function getTokenMarketValue(address, uint256) external pure returns (uint256) {
        return 250e18;
    }

    function stakingPool() external pure returns (address) {
        return address(0);
    }

    function cheddaGauge() external pure returns (address) {
        return address(0);
    }
}
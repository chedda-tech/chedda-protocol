// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IInterestRateModel } from "./IInterestRateModel.sol";
import { ILiquidityGauge } from "../gauge/ILiquidityGauge.sol";
import { IPriceFeed } from "../oracle/IPriceFeed.sol";

interface ILendingPool {
    function poolAsset() external view returns (ERC20);
    function characterization() external view returns (string memory);
    function supplied() external view returns (uint256);
    function borrowed() external view returns (uint256);
    function available() external view returns (uint256);
    function baseSupplyAPY() external view returns (uint256);
    function baseBorrowAPY() external view returns (uint256);
    function utilization() external view returns (uint256);
    function tvl() external view returns (uint256);
    function feesPaid() external view returns (uint256);
    function priceFeed() external view returns (IPriceFeed);
    function gauge() external view returns (ILiquidityGauge);
    function interestRateModel() external view returns (IInterestRateModel);
    function collaterals() external view returns (address [] memory);
}

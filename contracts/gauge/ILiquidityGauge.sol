//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface ILiquidityGauge {
    function claim() external;
    function rollover(uint256 balance, uint256 weight, uint256 rate) external;
    function setRewardRate(uint256 rate) external;
    function recordVote(address account) external;
    function rewardToken() external view returns (address);
    function rewardRate() external view returns (uint256); // ?
}

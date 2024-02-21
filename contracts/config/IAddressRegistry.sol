// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAddressRegistry {
    function cheddaToken() external view returns (address);
    function rewardsDistributor() external view returns (address);
}
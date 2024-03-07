// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAddressRegistry {
    function cheddaToken() external view returns (address);
    function rewardsDistributor() external view returns (address);
    function registeredPools() external view returns (address[] memory);
    function activePools() external view returns (address[] memory);
    function isRegisteredPool(address pool) external view returns (bool);
    function isActivePool(address pool) external view returns (bool);
}
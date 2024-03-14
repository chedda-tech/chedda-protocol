// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAddressRegistry} from "./IAddressRegistry.sol";

/// @title AddressRegistry
/// @notice Stores and retrieves commonly used addresses on the protocol.
contract AddressRegistry is Ownable, IAddressRegistry {

    event RewardsDistributorSet(address indexed caller, address indexed distributor);
    event CheddaSet(address indexed caller, address indexed chedda);
    event PoolRegistered(address indexed pool, address indexed caller);
    event PoolUnregistered(address indexed pool, address indexed caller);

    error AlreadyRegistered(address pool);
    error NotRegistered(address pool);

    address private _rewardsDistributor;
    address private _cheddaToken;
    address private _lendingPoolLens;
    address private _accountLens;
    address private _rewardLens;
    address[] private _pools;
    mapping (address => bool) private _activePools;

    constructor(address admin) Ownable(admin) {}

    /// @inheritdoc	IAddressRegistry
    function rewardsDistributor() external view returns (address) {
        return _rewardsDistributor;
    }

    /// @inheritdoc	IAddressRegistry
    function cheddaToken() external view returns (address) {
        return _cheddaToken;
    }

    /// @notice Sets the rewards distributor
    /// @dev Can only be called by the owner. 
    /// emits RewardsDistributorSet(address caller, address distributor) event
    /// @param distributor The new rewards distributor
    function setRewardsDistributor(address distributor) external onlyOwner() {
        _rewardsDistributor = distributor;

        emit RewardsDistributorSet(msg.sender, distributor);
    }

    /// @notice Explain to an end user what this does
    /// @dev Can only be called by the owner. 
    /// emits CheddaSet(address caller, address cheddaToken) event
    /// @param chedda New chedda token address 
    function setCheddaToken(address chedda) external onlyOwner() {
        _cheddaToken = chedda;

        emit CheddaSet(msg.sender, chedda);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                 Pool management
    ///////////////////////////////////////////////////////////////////////////


    /// @notice Registers a new lending pool
    /// @dev Can only be called by owner
    /// Reverts if pools is already registered.
    /// Emits PoolRegistered(address pool, address caller)
    /// @param pool The address of pool.
    /// @param isActive The active state of pool used for filtering.
    function registerPool(address pool, bool isActive) external onlyOwner() {
        if (isRegisteredPool(pool)) {
            revert AlreadyRegistered(pool);
        }
        _pools.push(pool);
        _activePools[pool] = isActive;

        emit PoolRegistered(pool, msg.sender);
    }

    /// @notice Unregisters a lending pool
    /// @dev Can only be called by admin. Reverts if pool is not registered
    /// Emits PoolRegistered(address pool, address caller)
    /// @param pool The pool to register
    function unregisterPool(address pool) external onlyOwner() {
        if (!isRegisteredPool(pool)) {
            revert NotRegistered(pool);
        }
        uint256 foundIndex = type(uint256).max;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i] == pool) {
                foundIndex = i;
            }
        }
        if (foundIndex != type(uint256).max) {
            _pools[foundIndex] = _pools[_pools.length - 1];
            _pools.pop();
            _activePools[pool] = false;

            emit PoolUnregistered(pool, msg.sender);
        }
    }

    /// @notice Sets a pool as active
    /// @dev Pools can be filtered by their active state
    /// @param pool The pool to set active or inactive
    /// @param isActive boolean flag to set pool as active or not
    function setActive(address pool, bool isActive) external onlyOwner() {
        if (!isRegisteredPool(pool)) {
            revert NotRegistered(pool);
        }
        _activePools[pool] = isActive;
    }

    /// @notice checks if a pool is already registered
    /// @param pool The address to check for
    /// @return Returns true if the pool address is registered
    function isRegisteredPool(address pool) public view returns (bool) {
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i] == pool) {
                return true;
            }
        }
        return false;
    }

    /// @notice checks if a pool is active
    /// @param pool The address to check for
    /// @return Returns true if the pool address is registered
    function isActivePool(address pool) public view returns (bool) {
        return _activePools[pool];
    }

    /// @notice Returns a list of all the registered pools
    /// @return pools The addresses of all registered pools
    function registeredPools() external view returns (address[] memory) {
        return _pools;
    }

    /// @notice Returns a list of all the active pools
    /// @return pools The addresses of all active pools
    function activePools() external view returns (address[] memory) {
        uint256 numberActive = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_activePools[_pools[i]]) {
                numberActive += 1;
            }
        }
        if (numberActive == 0) {
            return new address[](0);
        }
        address[] memory pools = new address[](numberActive);
        uint256 j = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_activePools[_pools[i]]) {
                pools[j++] = _pools[i];
            }
        }
        return pools;
    }
}

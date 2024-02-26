// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAddressRegistry} from "./IAddressRegistry.sol";

/// @title AddressRegistry
/// @notice Stores and retrieves commonly used addresses on the protocol.
contract AddressRegistry is Ownable, IAddressRegistry {

    event RewardsDistributorSet(address indexed caller, address indexed distributor);
    event CheddaSet(address indexed caller, address indexed chedda);

    address private _rewardsDistributor;
    address private _chedda;

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc	IAddressRegistry
    function rewardsDistributor() external view returns (address) {
        return _rewardsDistributor;
    }

    /// @inheritdoc	IAddressRegistry
    function cheddaToken() external view returns (address) {
        return _chedda;
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
        _chedda = chedda;

        emit CheddaSet(msg.sender, chedda);
    }
}

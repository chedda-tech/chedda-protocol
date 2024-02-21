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

    function rewardsDistributor() external view returns (address) {
        return _rewardsDistributor;
    }

    function cheddaToken() external view returns (address) {
        return _chedda;
    }

    function setRewardsDistributor(address distributor) external onlyOwner() {
        _rewardsDistributor = distributor;

        emit RewardsDistributorSet(msg.sender, distributor);
    }

    function setChedda(address chedda) external onlyOwner() {
        _chedda = chedda;

        emit CheddaSet(msg.sender, chedda);
    }
}

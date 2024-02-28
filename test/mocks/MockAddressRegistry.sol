// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IAddressRegistry} from "../../contracts/config/IAddressRegistry.sol";

contract MockAddressRegistry is IAddressRegistry {
    
    address private _chedda;
    address private _distributor;

    function cheddaToken() external view returns (address) {
        return _chedda;
    }

    function rewardsDistributor() external view returns (address) {
        return _distributor;
    }

    function setCheddaToken(address chedda) external {
        _chedda = chedda;
    }

    function setRewardsDistributor(address distributor) external {
        _distributor = distributor;
    }
}
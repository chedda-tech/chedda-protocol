// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {IAddressRegistry} from "../../contracts/config/IAddressRegistry.sol";

contract MockAddressRegistry is IAddressRegistry {
    
    address private _actor;
    address private _chedda;
    address private _cheddaOracle;
    address private _distributor;

    function accountActor() external view returns (address) {
        return _actor;
    }

    function cheddaToken() external view returns (address) {
        return _chedda;
    }

    function cheddaPriceOracle() external view returns (address) {
        return _cheddaOracle;
    }
    function rewardsDistributor() external view returns (address) {
        return _distributor;
    }

    function setCheddaToken(address chedda) external {
        _chedda = chedda;
    }

    function setCheddaPriceOracle(address oracle) external {
        _cheddaOracle = oracle;
    }

    function setRewardsDistributor(address distributor) external {
        _distributor = distributor;
    }

    function setAccountActor(address actor) external {
        _actor = actor;
    }

    function registeredPools() external virtual view returns (address[] memory) {
        return new address[](0);
    }

    function activePools() external virtual view returns (address[] memory) {
        return new address[](0);
    }

    function isRegisteredPool(address) external pure returns (bool) {
        return true;
    }

    function isActivePool(address) external pure returns (bool) {
        return true;
    }

}

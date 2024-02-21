// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IAddressRegistry} from "../../contracts/config/IAddressRegistry.sol";

contract MockAddressRegistry is IAddressRegistry {
    
    function cheddaToken() external pure returns (address) {
        return address(1);
    }

    function rewardsDistributor() external pure returns (address) {
        return address(2);
    }
}
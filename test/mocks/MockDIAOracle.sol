// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IDIAOracleV2} from "../../contracts/oracle/IDIAOracleV2.sol";

contract MockDIAOracle is IDIAOracleV2 {

    mapping (string => uint128) public values;
    mapping (string => uint128) public times;

    function setValue(string memory key, uint128 value) external {
        values[key] = value;
        times[key] = uint128(block.timestamp);
    }

    function getValue(string memory key) external view returns (uint128 lastPrice, uint128 lastUpdated) {
        return (values[key], times[key]);
    }
}

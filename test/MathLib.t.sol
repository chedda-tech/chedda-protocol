// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MathLib} from "../contracts/library/MathLib.sol";

contract MathLibTest is Test {

    using MathLib for uint256;

    function testNormalize() external pure {
        uint256 value18 = 10e18;
        uint256 value8 = 10e8;

        assertEq(value8, value18.normalized(18, 8));
        assertEq(value18, value8.normalized(8, 18));
    }
}
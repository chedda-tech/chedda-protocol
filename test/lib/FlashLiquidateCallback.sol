// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IFlashLiquidationCallback} from "../../contracts/pool/IFlashLiquidationCallback.sol";

contract FlashLiquidateCallback is IFlashLiquidationCallback {
    function execute(bytes memory data) external {
        // decode params
        // perform swap
        // transfer tokens to pool       
    }
}

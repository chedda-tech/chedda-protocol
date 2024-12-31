// SPDX-Licence-Identifier: BUSL-1.1
pragma solidity 0.8.27;

interface IFlashLiquidationCallback {
    function execute(bytes calldata data) external;
}

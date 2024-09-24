// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import { OFT } from "@layerzero-v2/contracts/oft/OFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CheddaTokenBridged
/// @notice CHEDDA token contract deployed to chains other than the base chain.
contract CheddaTokenBridged is OFT {

    /// @notice Construct a new Chedda token.
    /// @param lzEndpoint The LayerZero endpoint.
    /// @param delegate The contract owner. Can configure OFT.
    constructor(address lzEndpoint, address delegate)
    OFT("Chedda", "CHEDDA", lzEndpoint, delegate)
    Ownable(delegate) {}
}

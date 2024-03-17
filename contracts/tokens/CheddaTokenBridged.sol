// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { OFT } from "@layerzero-v2/contracts/oft/OFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CheddaTokenBridged
/// @notice CHEDDA token contract deployed to chains other than the base chain.
contract CheddaTokenBridged is OFT {

    /// @notice Construct a new Chedda token.
    /// @param owner The contract owner. Initial suppply is minted to this owner.
    /// @param lzEndpoint The LayerZero endpoint.
    constructor(address owner, address lzEndpoint)
    OFT("Chedda", "CHEDDA", lzEndpoint, owner)
    Ownable(owner) {}
}

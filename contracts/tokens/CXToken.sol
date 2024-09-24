// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import { OFT } from "@layerzero-v2/contracts/oft/OFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CXToken
/// @notice Chedda crosschain token.
/// @dev Used on the other end of tokens transfered using CheddaOFTAdapter
contract CXToken is OFT {

    /// @notice Construct a new Chedda token.
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param lzEndpoint The LayerZero endpoint.
    /// @param delegate The OFT delegate.
    constructor(string memory name, string memory symbol, address lzEndpoint, address delegate)
    OFT(name, symbol, lzEndpoint, delegate)
    Ownable(delegate) {}
}

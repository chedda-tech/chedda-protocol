// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { OFTAdapter } from "@layerzero-v2/contracts/oft/OFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CheddaOFTAdapter
/// @notice Adapter for briding transfer any ERC-20 token across chains.
/// @dev A `CheddaOFTAdapter` is deployed for each token that needs to be transferred across chains.
contract CheddaOFTAdapter is OFTAdapter {

    constructor(address _token, address _lzEndpoint, address _delegate)
    OFTAdapter(_token, _lzEndpoint, _delegate)
    Ownable(_delegate) {}
}

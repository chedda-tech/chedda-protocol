// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Time } from "../common/Types.sol";

/// @title Chedda
/// @notice Chedda token
contract Chedda  is ERC20, Ownable {

    uint256 public lastRebase;
    uint256 public constant INITIAL_SUPPLY = 400_000_000 * 1 ** DECIMALS;
    uint8 public constant DECIMALS = 18;

    /// @notice Construct a new Chedda token.
    /// @param custodian The token custodian to mint initial supply to.
    constructor(address custodian)
    ERC20("Chedda", "CHEDDA") {
        lastRebase = block.timestamp;
        _mint(custodian, INITIAL_SUPPLY);
    }

    function decimals() public view virtual override returns (uint8) {  
        return DECIMALS;
    }
}

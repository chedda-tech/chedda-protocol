// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { ERC20 } from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) 
    ERC20(name, symbol, decimals) {
        _mint(msg.sender, totalSupply);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    // function decimals() public view virtual override returns (uint8) {        
    //     return _decimals;
    // }
}


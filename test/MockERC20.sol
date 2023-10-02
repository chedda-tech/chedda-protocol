// SPDX-License-Identifier: BUSL-1.1-3.0-or-later
pragma solidity ^0.8.17;

// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(string memory name, string memory symbol, uint256 totalSupply) ERC20(name, symbol, 18) {
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


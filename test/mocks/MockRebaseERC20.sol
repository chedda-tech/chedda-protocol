// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IRebaseToken } from "../../contracts/tokens/IRebaseToken.sol";

contract MockRebaseERC20 is ERC20, IRebaseToken {

    address public _receiver;
    uint8 _decimals;
    
    constructor(string memory name, string memory symbol, uint8 d, uint256 totalSupply, address receiver)
    ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
        _decimals = d;
        _receiver = receiver;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function rebase() external returns (uint256) {
        uint256 amount = 1000 * 1 ** decimals();
        _mint(_receiver, amount);
        return amount;
    }

    function decimals() public view virtual override returns (uint8) {        
        return _decimals;
    }
}

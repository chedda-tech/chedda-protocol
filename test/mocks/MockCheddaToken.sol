// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ICheddaToken} from "../../contracts/tokens/ICheddaToken.sol";

contract MockCheddaToken is ERC20, ICheddaToken {

    address private _tokenReceiver;
    uint256 private _mintAmount = 100e18;

    constructor() ERC20("MockChedda", "MCD") {}

    function rebase() external returns (uint256) {
        if (_tokenReceiver != address(0) && _mintAmount != 0) {
            _mint(_tokenReceiver, _mintAmount);
            return _mintAmount;
        }
        return 0;
    }
    
    function mint(address account, uint256 value) external {
        _mint(account, value);
    }
    
    function emissionPerSecond() external view returns (uint256) {
        return _mintAmount;
    }
}
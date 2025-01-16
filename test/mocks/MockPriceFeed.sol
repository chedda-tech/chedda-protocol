// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { IPriceFeed } from "../../contracts/oracle/IPriceFeed.sol";

contract MockPriceFeed is IPriceFeed, Ownable {

    error ZeroAddress();

    // token address to price feed address
    mapping(address => int256) private _prices;
    mapping(address => string) private _symbols;

    uint8 public decimals;
    constructor(uint8 _decimals) Ownable(msg.sender) {
        decimals = _decimals;
    }
    

    /// @notice Sets the priceed feed for a token
    /// @param _token The token address
    /// @param _price The price of token
    function setPrice(address _token, int256 _price) public onlyOwner {
        _prices[_token] = _price;
    }

    /// @notice Returns the price of specified token.
    /// @param _token The token to get price for.
    /// @return price the latest price
    function readPrice(
        address _token
    ) public view override returns (int price, uint256 lastUpdated) {
        if (_token == address(0)) {
            revert ZeroAddress();
        }
        price = _prices[_token];
        lastUpdated = block.timestamp;
    }

    function token() external pure returns (address) {
        return address(0);
    }
}

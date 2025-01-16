// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {MockDIAOracle} from "./mocks/MockDIAOracle.sol";
import {DIAPriceFeed} from "../contracts/oracle/DIAPriceFeed.sol";

contract DIAPriceFeedTest is Test {

    DIAPriceFeed public priceFeed;
    MockDIAOracle public oracle;
    address public ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public btcAddress = 0xbad4bD599A9F537b70e711526565f7956a7aF00D;
    string public ethKey = "ETHUSD";
    string public btcKey = "BTCUSD";

    function setUp() public {
        oracle = new MockDIAOracle();
        DIAPriceFeed.FeedKeyMap[] memory keyMap = new DIAPriceFeed.FeedKeyMap[](2);

        keyMap[0] = DIAPriceFeed.FeedKeyMap({
            key: ethKey,
            tokenAddress: ethAddress
        });
        keyMap[1] = DIAPriceFeed.FeedKeyMap({
            key: btcKey,
            tokenAddress: btcAddress
        });
        priceFeed = new DIAPriceFeed(address(oracle), 8, keyMap);
    }

    function testReadPrice() public {
        uint128 ethPrice = 3200 * 1e8;
        uint128 btcPrice = 85000 * 1e8;
        oracle.setValue(ethKey, ethPrice);
        oracle.setValue(btcKey, btcPrice);
        
        (int256 p1, ) = priceFeed.readPrice(ethAddress);
        assertEq(p1, int256(uint256(ethPrice)));
        (int256 p2, ) = priceFeed.readPrice(btcAddress);
        assertEq(p2, int256(uint256(btcPrice)));
        (int256 p3, ) = priceFeed.readPrice(address(0));
        assertEq(p3, 0);
    }
}

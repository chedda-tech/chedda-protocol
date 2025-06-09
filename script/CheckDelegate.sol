// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.27;

import {Script, console2} from "forge-std/Script.sol";

contract A {
    function a() public pure returns(uint256) {
        return 2;
    }
}

contract B {
    event GotReturn(uint rv);
    address addrOfA;
    constructor (address _addrOfA) {
        addrOfA = _addrOfA;
    }
    
    function b() public returns(uint256) {
        (bool success, bytes memory result) = address(addrOfA).delegatecall(abi.encodeWithSignature("a()"));
        require(success);
        
        uint256 rv = abi.decode(result, (uint256));
        emit GotReturn(rv);
        return rv;
    }
}

contract MyScript is Script {
    function run() external {
        A a = new A();
        B b = new B(address(a));
        uint256 rv = b.b();
        console2.log("rv = %d", rv);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MultiUtilityNFT} from "../src/MultiUtilityNFT.sol";

contract MultiUtilityNFTTest is Test {
    MultiUtilityNFT public multiUtilityNFT;

    function setUp() public {
        multiUtilityNFT = new MultiUtilityNFT();
        multiUtilityNFT.setNumber(0);
    }

    function test_Increment() public {
        multiUtilityNFT.increment();
        assertEq(multiUtilityNFT.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        multiUtilityNFT.setNumber(x);
        assertEq(multiUtilityNFT.number(), x);
    }
}

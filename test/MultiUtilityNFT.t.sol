// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MultiUtilityNFT} from "../src/MultiUtilityNFT.sol";
import {PaymentToken} from "../src/PaymentToken.sol";

contract MultiUtilityNFTTest is Test {
    MultiUtilityNFT public multiUtilityNFT;
    PaymentToken public paymentToken;

    function setUp() public {
        paymentToken = new PaymentToken();
        multiUtilityNFT = new MultiUtilityNFT(
            "MultiUtilityNFT",
            "MUN",
            paymentToken,
            0,
            0,
            bytes32(0),
            bytes32(0),
            block.timestamp,
            block.timestamp,
            block.timestamp
        );
    }
}

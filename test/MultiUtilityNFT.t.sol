// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MultiUtilityNFT} from "../src/MultiUtilityNFT.sol";
import {PaymentToken} from "../src/PaymentToken.sol";

contract MultiUtilityNFTTest is Test {
    MultiUtilityNFT public multiUtilityNFT;
    PaymentToken public paymentToken;

    enum Phase {
        Phase1,
        Phase2,
        Phase3,
        Finished
    }

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

    function getCurrentPhase() public view returns (Phase) {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp <= multiUtilityNFT.phase1EndTimestamp()) {
            return Phase.Phase1;
        } else if (currentTimestamp <= multiUtilityNFT.phase2EndTimestamp()) {
            return Phase.Phase2;
        } else if (currentTimestamp <= multiUtilityNFT.phase3EndTimestamp()) {
            return Phase.Phase3;
        } else {
            return Phase.Finished;
        }
    }
}

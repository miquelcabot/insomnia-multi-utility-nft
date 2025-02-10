// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MultiUtilityNFT is ERC721 {
    using SafeERC20 for IERC20;

    enum Phase {
        Phase1,
        Phase2,
        Phase3,
        Finished
    }

    IERC20 public immutable paymentToken;
    uint256 public immutable discountPrice;
    uint256 public immutable fullPrice;
    bytes32 public immutable phase1MerkleRoot;
    bytes32 public immutable phase2MerkleRoot;
    uint256 public immutable phase1EndTimestamp;
    uint256 public immutable phase2EndTimestamp;
    uint256 public immutable phase3EndTimestamp;

    constructor(
        string memory name,
        string memory symbol,
        IERC20 _paymentToken,
        uint256 _discountPrice,
        uint256 _fullPrice,
        bytes32 _phase1MerkleRoot,
        bytes32 _phase2MerkleRoot,
        uint256 _phase1EndTimestamp,
        uint256 _phase2EndTimestamp,
        uint256 _phase3EndTimestamp
    ) ERC721(name, symbol) {
        paymentToken = _paymentToken;
        discountPrice = _discountPrice;
        fullPrice = _fullPrice;
        phase1MerkleRoot = _phase1MerkleRoot;
        phase2MerkleRoot = _phase2MerkleRoot;
        phase1EndTimestamp = _phase1EndTimestamp;
        phase2EndTimestamp = _phase2EndTimestamp;
        phase3EndTimestamp = _phase3EndTimestamp;
    }

    function getCurrentPhase() public view returns (Phase) {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp <= phase1EndTimestamp) {
            return Phase.Phase1;
        } else if (currentTimestamp <= phase2EndTimestamp) {
            return Phase.Phase2;
        } else if (currentTimestamp <= phase3EndTimestamp) {
            return Phase.Phase3;
        } else {
            return Phase.Finished;
        }
    }
}

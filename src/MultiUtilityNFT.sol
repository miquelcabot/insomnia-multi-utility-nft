// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MultiUtilityNFT is ERC721 {
    using SafeERC20 for IERC20;

    IERC20 public immutable paymentToken;
    uint256 public immutable discountPrice;
    uint256 public immutable fullPrice;
    bytes32 public immutable merkleRootPhase1;
    bytes32 public immutable merkleRootPhase2;

    constructor(
        string memory name,
        string memory symbol,
        IERC20 _paymentToken,
        uint256 _discountPrice,
        uint256 _fullPrice,
        bytes32 _merkleRootPhase1,
        bytes32 _merkleRootPhase2
    ) ERC721(name, symbol) {
        paymentToken = _paymentToken;
        discountPrice = _discountPrice;
        fullPrice = _fullPrice;
        merkleRootPhase1 = _merkleRootPhase1;
        merkleRootPhase2 = _merkleRootPhase2;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title PaymentToken
 * @notice A simple ERC20 token for testing purposes
 */
contract PaymentToken is ERC20 {
    /**
     * @notice Construct a new PaymentToken
     * @dev The token has the name "PaymentToken" and the symbol "PT"
     */
    constructor() ERC20("PaymentToken", "PT") {}

    /**
     * @notice Mint new tokens
     * @dev Anyone can mint new tokens for testing purposes
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

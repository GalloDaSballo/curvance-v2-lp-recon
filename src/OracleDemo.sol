// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FixedPointMathLib} from "./FixedPointMathLib.sol";

contract OracleDemo {
    // Lending Protocol
    // X Tokens
    // X * calculate_lp_token_price()

    // Little deposit -> Masive price = overborrow

    function calculate_lp_token_price(
        uint256 total_supply,
        uint256 price0,
        uint256 price1,
        uint256 reserve0,
        uint256 reserve1
    ) external pure returns (uint256) {
        uint256 a = FixedPointMathLib.sqrt(reserve0 * reserve1);
        uint256 b = FixedPointMathLib.sqrt(price0 * price1);
        uint256 c = 2 * a * b / total_supply;

        return c;
    }
}

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
        uint256 a = sqrt(reserve0 * reserve1);
        uint256 b = sqrt(price0 * price1);
        uint256 c = 2 * a * b / total_supply;

        return c;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {Setup} from "./Setup.sol";

abstract contract Properties is Setup, Asserts {
    function crytic_price_cannot_change() public view returns (bool) {
        return initialPrice
            == oracleDemo.calculate_lp_token_price(pool.totalSupply(), price0, price1, pool.reserve0(), pool.reserve1());
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";

import "src/OracleDemo.sol";
import "src/Pool.sol";
import "src/MockERC20.sol";

abstract contract Setup is BaseSetup {
    Pool pool;
    OracleDemo oracleDemo;
    MockERC20 tokenA;
    MockERC20 tokenB;

    uint256 initialPrice;

    uint256 price0 = 1e18;
    uint256 price1 = 1e18; // anpther

    function setup() internal virtual override {
        pool = new Pool();
        oracleDemo = new OracleDemo();

        tokenA = new MockERC20();
        tokenB = new MockERC20();

        // Classic unstable Pool
        pool.initialize(address(tokenA), address(tokenB), true);

        // Set the pool at 1:1
        tokenA.transfer(address(pool), 1000e18);
        tokenB.transfer(address(pool), 1000e18);

        pool.mint(address(this));

        initialPrice =
            oracleDemo.calculate_lp_token_price(pool.totalSupply(), price0, price1, pool.reserve0(), pool.reserve1());
    }
}

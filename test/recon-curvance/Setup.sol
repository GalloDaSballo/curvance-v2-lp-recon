// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {AnyFactory} from "src/AnyFactory.sol";
import "src/OracleDemo.sol";
import "src/Pool.sol";
import "src/MockERC20.sol";
import {vm} from "@chimera/Hevm.sol";
abstract contract Setup is BaseSetup {
    Pool pool;
    OracleDemo oracleDemo;
    MockERC20 tokenA;
    MockERC20 tokenB;

    uint256 initialPrice;

    uint256 price0 = 1e18;
    uint256 price1 = 1e18; // anpther asd

    address uniV2Pool;

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

    function feeTo() external view returns (address) {
        // Returns 0
    }

    function _setupFork() internal {
        AnyFactory factory = new AnyFactory();
        uniV2Pool = factory.deploy();

        vm.store(address(uniV2Pool), bytes32(uint256(5)), bytes32(abi.encode(address(this)))); // Factory, prob unused
        vm.store(address(uniV2Pool), bytes32(uint256(6)), bytes32(abi.encode(tokenA))); // Token0
        vm.store(address(uniV2Pool), bytes32(uint256(7)), bytes32(abi.encode((tokenB)))); // Token1
    }
}

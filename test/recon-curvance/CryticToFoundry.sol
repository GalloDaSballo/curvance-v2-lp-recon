// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

interface IPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    // TODO: Add rest for invariant testing
}

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
        _setupFork();
    }

    function testDemoPseudoFork() public {
        // TODO: Given any target function and foundry assert, test your results
        console2.log("token0", IPool(uniV2Pool).token0());
        console2.log("token1", IPool(uniV2Pool).token1());
        console2.log("totalSupply", IPool(uniV2Pool).totalSupply());

        // Shows that our code does indeed work
        // Set the pool at 1:1
        tokenA.transfer(address(uniV2Pool), 1000e18);
        tokenB.transfer(address(uniV2Pool), 1000e18);

        console2.log("tokenA.balanceOf(uniV2Pool)", tokenA.balanceOf(uniV2Pool));

        IPool(uniV2Pool).mint(address(this));
        console2.log("Balance", IPool(uniV2Pool).balanceOf(address(this)));
    }


}

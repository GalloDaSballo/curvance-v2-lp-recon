// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {IUniV2Pool} from "src/IUniV2Pool.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
    }

    /// @dev shows that etched code works
    function testDemoPseudoFork() public {
        // TODO: Given any target function and foundry assert, test your results
        console2.log("token0", IUniV2Pool(uniV2Pool).token0());
        console2.log("token1", IUniV2Pool(uniV2Pool).token1());
        console2.log("totalSupply", IUniV2Pool(uniV2Pool).totalSupply());

        // Shows that our code does indeed work
        // Set the pool at 1:1
        tokenA.transfer(address(uniV2Pool), 1000e18);
        tokenB.transfer(address(uniV2Pool), 1000e18);

        console2.log("tokenA.balanceOf(uniV2Pool)", tokenA.balanceOf(uniV2Pool));

        IUniV2Pool(uniV2Pool).mint(address(this));
        console2.log("Balance", IUniV2Pool(uniV2Pool).balanceOf(address(this)));
    }

    /// @dev shows that we can achieve a 25x manipulation via donation
    function test_crytic_price_cannot_change_byThresholdUp_25x() public {
        console2.log("initialPrice", initialPrice);
        console2.log("getCurrentPrice()", getCurrentPrice());
        donateToken1(900000000000000000000);
        console2.log("getCurrentPrice()", getCurrentPrice());
        donateBoth(11155111);
        console2.log("getCurrentPrice()", getCurrentPrice());
        pool_mint(0x5FCCD64057fB44A80Bcf4faf92D44D6795F764a1);
        console2.log("getCurrentPrice()", getCurrentPrice());
    }

    /// @dev shows that the formula holds only if you use the swap router
    /// The swap router maximizes the tokens out, meaning it doesn't impact the reserves
    /// The attack above, "self-rekts" impacting the ratio of reserves and attacking the formula
    function test_crytic_price_cannot_change_experiment() public {
        console2.log("initialPrice", initialPrice);
        console2.log("getCurrentPrice()", getCurrentPrice());

        // NOTE: See how when using the router it's impossible to make the price move too much
        // This is because the invariant x*y=k is being held
        // But when we just donate to reserves, that's no longer the case
        while (getCurrentPrice() < 3006553686384643624) {
            _doASwap(1e18);
        }
    }

    function _doASwap(uint256 amt) internal {
        (uint256 reserve0, uint256 reserve1,) = IUniV2Pool(uniV2Pool).getReserves();
        uint256 findAccurateSwapAmountFromLib = _getAmountOut(amt, reserve1, reserve0);
        // Swap shit
        donateToken1(amt);
        swap(findAccurateSwapAmountFromLib, 0, address(this));
        console2.log("getCurrentPrice()", getCurrentPrice());
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}

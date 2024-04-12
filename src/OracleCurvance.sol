// interface IUniswapV2Pair {

// }
// contract OracleCurvance {

//   address asset;
//   address token0;
//   address token1;

// function getPrice(
//         address asset,
//         bool inUSD,
//         bool getLower
//     ) public view returns (PriceReturnData memory pData) {

//         // Cache AdaptorData and grab pool tokens.
//         // AdaptorData memory data = adaptorData[asset]; // NOTE: Replace by token0 and token1
//         IUniswapV2Pair pool = IUniswapV2Pair(asset);

//         // Query LP total supply.
//         uint256 totalSupply = pool.totalSupply();
//         // Query LP reserves.
//         (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
//         // convert to 18 decimals.
//         reserve0 = (reserve0 * 1e18) / (10 ** data.decimals0);
//         reserve1 = (reserve1 * 1e18) / (10 ** data.decimals1);

//         // sqrt(reserve0 * reserve1).
//         uint256 sqrtReserve = FixedPointMathLib.sqrt(reserve0 * reserve1);

//         uint256 price0;
//         uint256 price1;
//         uint256 errorCode;

//         IOracleRouter oracleRouter = IOracleRouter(
//             centralRegistry.oracleRouter()
//         );
//         (price0, errorCode) = oracleRouter.getPrice(
//             data.token0,
//             inUSD,
//             getLower
//         );

//         // Validate we did not run into any errors pricing token0.
//         if (errorCode > 0) {
//             pData.hadError = true;
//             return pData;
//         }

//         (price1, errorCode) = oracleRouter.getPrice(
//             data.token1,
//             inUSD,
//             getLower
//         );

//         // Validate we did not run into any errors pricing token1.
//         if (errorCode > 0) {
//             pData.hadError = true;
//             return pData;
//         }

//         // price = 2 * sqrt(reserve0 * reserve1) * sqrt(price0 * price1) / totalSupply.
//         uint256 finalPrice = (2 *
//             sqrtReserve *
//             FixedPointMathLib.sqrt(price0 * price1)) / totalSupply;

//         // Validate price will not overflow on conversion to uint240.
//         if (_checkOracleOverflow(finalPrice)) {
//             pData.hadError = true;
//             return pData;
//         }

//         pData.inUSD = inUSD;
//         pData.price = uint240(finalPrice);
//     }
// }
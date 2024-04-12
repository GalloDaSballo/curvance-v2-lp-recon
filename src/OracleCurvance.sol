import {FixedPointMathLib} from "./FixedPointMathLib.sol";
import {IUniV2Pool} from "./IUniV2Pool.sol";

contract OracleCurvance {

function getPrice(
        address asset
    ) public view returns (uint256 finalPrice) {

        // Cache AdaptorData and grab pool tokens.
        // AdaptorData memory data = adaptorData[asset]; // NOTE: Replace by token0 and token1
        IUniV2Pool pool = IUniV2Pool(asset);

        // Query LP total supply.
        uint256 totalSupply = pool.totalSupply();
        if(totalSupply == 0) {
            return 0;
        }
        // Query LP reserves.
        (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
        // convert to 18 decimals.
        reserve0 = (reserve0 * 1e18) / (10 ** 18);
        reserve1 = (reserve1 * 1e18) / (10 ** 18);

        // sqrt(reserve0 * reserve1).
        uint256 sqrtReserve = FixedPointMathLib.sqrt(reserve0 * reserve1);


        uint256 price0 = 1e18;
        uint256 price1 = 1e18;


        // price = 2 * sqrt(reserve0 * reserve1) * sqrt(price0 * price1) / totalSupply.
        uint256 finalPrice = (2 *
            sqrtReserve *
            FixedPointMathLib.sqrt(price0 * price1)) / totalSupply;


        return finalPrice;
    }
}
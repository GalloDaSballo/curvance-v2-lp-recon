// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

interface IPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;


    // TODO: Add rest for invariant testing
}

abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {


    function pool_mint(address to) public {
        IPool(uniV2Pool).mint(to);
    }
    
    function burn(address to) public {
        IPool(uniV2Pool).burn(to);
    }

    function swap(uint amount0Out, uint amount1Out, address to) public {
        IPool(uniV2Pool).swap(amount0Out, amount1Out, to, "");
    }

    function skim(address to) public {
        IPool(uniV2Pool).skim(to);
    }

    function sync() public {
        IPool(uniV2Pool).sync();
    }

    function donateToken0(uint256 amt) public {
        tokenA.transfer(uniV2Pool, amt);
    }
    function donateToken1(uint256 amt) public {
        tokenB.transfer(uniV2Pool, amt);
    }
    function donateBoth(uint256 amt) public {
        tokenA.transfer(uniV2Pool, amt);
        tokenB.transfer(uniV2Pool, amt);
    }

}

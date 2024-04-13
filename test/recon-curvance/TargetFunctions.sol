// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";
import {IUniV2Pool} from "src/IUniV2Pool.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {
    function pool_mint(address to) public {
        IUniV2Pool(uniV2Pool).mint(to);
    }

    function burn(address to) public {
        IUniV2Pool(uniV2Pool).burn(to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {
        IUniV2Pool(uniV2Pool).swap(amount0Out, amount1Out, to, "");
    }

    function skim(address to) public {
        IUniV2Pool(uniV2Pool).skim(to);
    }

    function sync() public {
        IUniV2Pool(uniV2Pool).sync();
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

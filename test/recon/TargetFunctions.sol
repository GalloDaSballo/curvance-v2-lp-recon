// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {
    function pool_approve(address spender, uint256 value) public {
        pool.approve(spender, value);
    }

    function pool_burn(address to) public {
        pool.burn(to);
    }

    function pool_claimFees() public {
        pool.claimFees();
    }

    function pool_initialize(address _token0, address _token1, bool _stable) public {
        pool.initialize(_token0, _token1, _stable);
    }

    function donateToPool0(uint256 amt) public {
        tokenA.transfer(address(pool), amt);
    }

    function pool_mint(address to) public {
        pool.mint(to);
    }

    function pool_permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        pool.permit(owner, spender, value, deadline, v, r, s);
    }

    function pool_skim(address to) public {
        pool.skim(to);
    }

    function pool_swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) public {
        pool.swap(amount0Out, amount1Out, to, data);
    }

    function pool_sync() public {
        pool.sync();
    }

    function pool_transfer(address to, uint256 value) public {
        pool.transfer(to, value);
    }

    function pool_transferFrom(address from, address to, uint256 value) public {
        pool.transferFrom(from, to, value);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {Setup} from "./Setup.sol";

abstract contract Properties is Setup, Asserts {
    uint256 RECON_THRESHOLD = 25;
    function crytic_price_cannot_change_byThresholdUp() public view returns (bool) {
        return initialPrice * RECON_THRESHOLD
            >= getCurrentPrice();
    }
    function crytic_price_cannot_change_byThresholdDown() public view returns (bool) {
        return initialPrice 
            <= getCurrentPrice() * RECON_THRESHOLD;
    }
}

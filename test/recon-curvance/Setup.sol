// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {AnyFactory} from "src/AnyFactory.sol";
import "src/OracleCurvance.sol";
import "src/Pool.sol";
import "src/MockERC20.sol";
import {vm} from "@chimera/Hevm.sol";
import {IUniV2Pool} from "src/IUniV2Pool.sol";

contract MockFactory {
    function feeTo() external view returns (address) {
        // Returns 0
    }
}

abstract contract Setup is BaseSetup {
    OracleCurvance oracle;
    MockERC20 tokenA;
    MockERC20 tokenB;
    MockFactory mockFactory;

    uint256 initialPrice;

    uint256 price0 = 1e18;
    uint256 price1 = 1e18; // anpther asd

    address uniV2Pool;

    function setup() internal virtual override {
        mockFactory = new MockFactory();
        tokenA = new MockERC20();
        tokenB = new MockERC20();  

        _setupFork();

        // Initial Even Mint
        tokenA.transfer(uniV2Pool, 1_000_000e18);
        tokenB.transfer(uniV2Pool, 1_000_000e18);
        IUniV2Pool(uniV2Pool).mint(address(this));

        oracle = new OracleCurvance();
        initialPrice = getCurrentPrice();    


    }

    function getCurrentPrice() public view returns (uint256) {
        return oracle.getPrice(uniV2Pool);
    }



    function _setupFork() internal {
        AnyFactory factory = new AnyFactory();
        uniV2Pool = factory.deploy();

        vm.store(address(uniV2Pool), bytes32(uint256(5)), bytes32(abi.encode(address(mockFactory)))); // Factory, used for feeTo
        vm.store(address(uniV2Pool), bytes32(uint256(6)), bytes32(abi.encode(tokenA))); // Token0
        vm.store(address(uniV2Pool), bytes32(uint256(7)), bytes32(abi.encode((tokenB)))); // Token1
    }
}

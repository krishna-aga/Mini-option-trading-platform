// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Option} from "../src/Option.sol";
import {MockUSDT} from "../src/MockUSDT.sol";
contract DeployOption is Script {
   Option option;
   MockUSDT mockUSDT;
    function run() public {  
        vm.startBroadcast();

       mockUSDT = new MockUSDT(10000000);
       option = new Option(address(option));

        vm.stopBroadcast();
    }
}

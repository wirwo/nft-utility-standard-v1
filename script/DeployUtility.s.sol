// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {NFTUtilities} from "../src/utility.sol";

contract DeployUtility is Script {
    function run() external returns (NFTUtilities) {
        vm.startBroadcast();
        NFTUtilities utility = new NFTUtilities();
        vm.stopBroadcast();
        return utility;
    }
}
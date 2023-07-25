// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {NFTUtilities} from "../src/utility.sol";

contract DeployUtility is Script {
    function run() external returns (NFTUtilities) {
        vm.startBroadcast();
        NFTUtilities utility = new NFTUtilities(0x73A4b3b1a6C5C883ecD796D0dd5eD4f4e1E78d2b);
        vm.stopBroadcast();
        return utility;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {NFTUtilities} from "../src/utility.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployUtility is Script {
    function run() external returns (NFTUtilities) {
        HelperConfig helperConfig = new HelperConfig();
        address nftContract = helperConfig.activeNetworkConfig();
        
        vm.startBroadcast();
        NFTUtilities utility = new NFTUtilities(nftContract);
        vm.stopBroadcast();
        return utility;
    }
}
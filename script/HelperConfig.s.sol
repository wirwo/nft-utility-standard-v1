//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {SimpleERC721} from "../src/ERC721Sample.sol";

contract HelperConfig is Script{
  address public activeNetworkConfig;

  constructor() {
    if (block.chainid == 11155111){
      activeNetworkConfig = getAddressInSepolia();
    }
    else{
      activeNetworkConfig = getAddressInAnvil();
    }
  }

  function getAddressInSepolia() public pure returns (address) {
    return 0x73A4b3b1a6C5C883ecD796D0dd5eD4f4e1E78d2b;
  }

  function getAddressInAnvil() public returns (address) {
    if(activeNetworkConfig != address(0)){
      return activeNetworkConfig;
    }
    
    vm.startBroadcast();
    SimpleERC721 erc721 = new SimpleERC721();
    vm.stopBroadcast();

    return address(erc721);
  }

}
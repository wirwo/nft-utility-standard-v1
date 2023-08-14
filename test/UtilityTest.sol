// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployUtility} from "../script/DeployUtility.s.sol";
import {NFTUtilities} from "../src/utility.sol";

contract UtilityTest is Test {
  NFTUtilities utility;
  
  function setUp() external {
    DeployUtility deployUtility = new DeployUtility();
    utility = deployUtility.run();
  }

  // Test adding utility to specific tokens
  function testAddUtility() public {
  }

  // Test adding utility to all tokens
  function testAddUtilityToAll() public {
  }

  // Test editing an existing utility
  function testEditUtility() public {
  }

  // Test deleting a utility
  function testDeleteUtility() public {
  }

  // Test using a utility
  function testUseUtility() public {
  }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployUtility} from "../script/DeployUtility.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {NFTUtilities} from "../src/utility.sol";

contract UtilityTest is Test {
  NFTUtilities public utility;
  HelperConfig public helperConfig;
  
  function setUp() external {
    DeployUtility deployUtility = new DeployUtility();
    (utility, helperConfig) = deployUtility.run();
  }

  function testAddUtility() external {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        utility.addUtility(tokenIds, "testURI", 5, block.timestamp + 1 days);
        assertEq(utility.getUtility(1)[0].uri, "testURI");
        assertEq(utility.getUtility(1)[0].remainingUses, 5);
        assertEq(utility.getUtility(2)[0].uri, "testURI");
        assertEq(utility.getUtility(2)[0].remainingUses, 5);
    }

  function testAddUtilityToAll() external {
        utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
        assertEq(utility.getUtility(1)[0].uri, "testURI");
        assertEq(utility.getUtility(1)[0].remainingUses, 3);
        assertEq(utility.getUtility(8)[0].uri, "testURI");
        assertEq(utility.getUtility(8)[0].remainingUses, 3);
    }

    function testEditUtility() external {
        utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
        utility.editUtility(0, "newURI", 2, block.timestamp + 2 days);
        assertEq(utility.getUtility(1)[0].uri, "newURI");
        assertEq(utility.getUtility(1)[0].remainingUses, 2);
        assertEq(utility.getUtility(1)[0].expiryTimestamp, block.timestamp + 2 days);
    }

    function testDeleteUtility() external {
      utility.addUtilityToAll("testURI1", 3, block.timestamp + 1 days);
      utility.addUtilityToAll("testURI2", 3, block.timestamp + 1 days);
      utility.deleteUtility(0);
      assertEq(utility.getUtility(1).length, 1);
    }

    function testUseUtility() external {
        utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
        utility.useUtility(1, 0);
        assertEq(utility.getUtility(1)[0].remainingUses, 2);
    }
    
}
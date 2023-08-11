// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployUtility} from "../script/DeployUtility.s.sol";
import {NFTUtilities} from "../src/utility.sol";

contract UtilityTest is Test {
    function testDeployUtility() public {
        NFTUtilities utility = new DeployUtility().run();
        assertEq(address(utility), 0x73A4b3b1a6C5C883ecD796D0dd5eD4f4e1E78d2b);
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
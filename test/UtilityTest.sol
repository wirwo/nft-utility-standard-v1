SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeployUtility} from "../script/DeployUtility.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {NFTUtilities} from "../src/utility.sol";
import {SimpleERC721} from "../src/ERC721Sample.sol";


contract UtilityTest is Test {
NFTUtilities public utility;
HelperConfig public helperConfig;

address ALICE = makeAddr("alice");
address BEN = makeAddr("ben");

function setUp() external {
DeployUtility deployUtility = new DeployUtility();
(utility, helperConfig) = deployUtility.run();
}

//Test that the deployer is the owner of the contract
function testDeployerNotOwner() external{
vm.startPrank(ALICE);
SimpleERC721 erc721 = new SimpleERC721();
vm.stopPrank();

vm.prank(BEN);
vm.expectRevert();
utility = new NFTUtilities(address(erc721));
}

//Test for addiing a utility to a set of tokenIds
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

//Test for adding a utility to all tokens
function testAddUtilityToAll() external {
    utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
    assertEq(utility.getUtility(1)[0].uri, "testURI");
    assertEq(utility.getUtility(1)[0].remainingUses, 3);
    assertEq(utility.getUtility(8)[0].uri, "testURI");
    assertEq(utility.getUtility(8)[0].remainingUses, 3);
}

//Test for editing a utility
function testEditUtility() external {
    utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
    utility.editUtility(0, "newURI", 2, block.timestamp + 2 days);
    assertEq(utility.getUtility(1)[0].uri, "newURI");
    assertEq(utility.getUtility(1)[0].remainingUses, 2);
    assertEq(utility.getUtility(1)[0].expiryTimestamp, block.timestamp + 2 days);
}

//Test for deleting a utility
function testDeleteUtility() external {
    utility.addUtilityToAll("testURI1", 3, block.timestamp + 1 days);
    utility.addUtilityToAll("testURI2", 3, block.timestamp + 1 days);
    utility.deleteUtility(0);
    assertEq(utility.getUtility(1).length, 1);
}

//Test for using a utility
function testUseUtility() external {
    utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
    utility.useUtility(1, 0);
    assertEq(utility.getUtility(1)[0].remainingUses, 2);
}

//Test for adding utility to invalid set of tokenIds
function testInvalidTokenID() external {
    uint256[] memory tokenIds = new uint256[](2);
    tokenIds[0] = 999999; 
    tokenIds[1] = 1000000; 

    vm.expectRevert();
    utility.addUtility(tokenIds, "testURI", 5, block.timestamp + 1 days);
}

//Test for editing a non-existent utilityId
function testEditNonexistentUtility() external {
    utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
    vm.expectRevert();
    utility.editUtility(999999, "invalidURI", 5, block.timestamp + 1 days); 
}

//Test for deleting a non-existent utilityId
function testDeleteNonexistentUtility() external {
    utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
    vm.expectRevert();
    utility.deleteUtility(999999);
}

//Test for deleting a deleted utility
function testUseDeletedUtility() external {
    utility.addUtilityToAll("testURI", 3, block.timestamp + 1 days);
    utility.deleteUtility(0);
    
    vm.expectRevert();
    utility.useUtility(1, 0);
}

// Test for using an expired utilityId
// function testUseExpiredUtility() external {
//     utility.addUtilityToAll("testURI", 3, block.timestamp - 1 days); 
//     vm.expectRevert();
//     utility.useUtility(1, 0);
// }

//Test for using a utility of a tokenId that hasn't been assigned utility
function testTokenDoesNotHaveUtility() external {
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = 1;
    utility.addUtility(tokenIds, "testURI", 5, block.timestamp + 1 days);
    vm.expectRevert();
    utility.useUtility(2, 0);
}

//Test for using a utility that has no remaining uses
function testUtilityOutOfUse() external {
    utility.addUtilityToAll("testURI", 1, block.timestamp + 1 days);
    utility.useUtility(1, 0);
    vm.expectRevert();
    utility.useUtility(1, 0);
}

//Test for viewing utilities of a tokenId that exceeds supply
function testGetUtilityInvalidTokenId() external {
    vm.expectRevert();
    utility.getUtility(999999);
}

}
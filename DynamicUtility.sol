// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library DynamicUtilities {
    struct DynamicUtility {
        string name;
        string description;
        uint256 remainingUses;
        mapping(address => bool) isUsed;
        bool deleted;
    }

    function addDynamicUtility(DynamicUtility[] storage utilities, string memory utilityName, string memory utilityDescription, uint256 uses) internal {
        utilities.push();
        uint256 utilityIndex = utilities.length - 1;
        utilities[utilityIndex].name = utilityName;
        utilities[utilityIndex].description = utilityDescription;
        utilities[utilityIndex].remainingUses = uses;
        utilities[utilityIndex].deleted = false;
    }

    function editDynamicUtility(DynamicUtility storage utility, string memory newUtilityName, string memory newUtilityDescription, uint256 newUses) internal {
        utility.name = newUtilityName;
        utility.description = newUtilityDescription;
        utility.remainingUses = newUses;
    }

    function deleteDynamicUtility(DynamicUtility storage utility) internal {
        utility.deleted = true;
    }
    
}
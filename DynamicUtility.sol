// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library DynamicUtilities {
    struct DynamicUtility {
        uint256 id;
        string name;
        string description;
        uint256 remainingUses;
        bool deleted;
    }

    function addDynamicUtilityToAll(DynamicUtility storage utility, uint256 utilityId, string memory utilityName, string memory utilityDescription, uint256 uses) internal {
        utility.id = utilityId; 
        utility.name = utilityName;
        utility.description = utilityDescription;
        utility.remainingUses = uses;
        utility.deleted = false;
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
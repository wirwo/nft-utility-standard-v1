// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library DynamicUtilities {
    struct DynamicUtility {
        uint256 id;
        string name;
        string description;
        string image;
        string url;
        uint256 remainingUses;
        uint256 expiryTimestamp; //1672444799 -> 31 December 2023
        bool deleted;
    }

    function addDynamicUtilityToAll(DynamicUtility storage utility, uint256 utilityId, string memory utilityName, string memory utilityDescription, string memory utilityImage, string memory utilityUrl, uint256 uses, uint256 utilityExpiry) internal {
        utility.id = utilityId; 
        utility.name = utilityName;
        utility.description = utilityDescription;
        utility.image = utilityImage;
        utility.url = utilityUrl;
        utility.remainingUses = uses;
        utility.expiryTimestamp = utilityExpiry;
        utility.deleted = false;
    }

    function editDynamicUtility(DynamicUtility storage utility, string memory newUtilityName, string memory newUtilityDescription, string memory newUtilityImage, string memory newUtilityUrl, uint256 newUses, uint256 newExpiry) internal {
        utility.name = newUtilityName;
        utility.description = newUtilityDescription;
        utility.image = newUtilityImage;
        utility.url = newUtilityUrl;
        utility.remainingUses = newUses;
        utility.expiryTimestamp = newExpiry;
    }

    function deleteDynamicUtility(DynamicUtility storage utility) internal {
        utility.deleted = true;
    }
    
}
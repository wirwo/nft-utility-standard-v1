// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library StaticUtilities {
    struct StaticUtility {
        uint256 id;
        string name;
        string description;
        string url;
        bool deleted;
    }

    function addStaticUtilityToAll(StaticUtility storage utility, uint256 utilityId, string memory utilityName, string memory utilityDescription, string memory utilityUrl) internal {
        utility.id = utilityId; 
        utility.name = utilityName;
        utility.description = utilityDescription;
        utility.url = utilityUrl;
        utility.deleted = false;
    }
    
    function editStaticUtility(StaticUtility storage utility, string memory newUtilityName, string memory newUtilityDescription, string memory newUtilityUrl) internal {
        utility.name = newUtilityName;
        utility.description = newUtilityDescription;
        utility.url = newUtilityUrl;
    }

    function deleteStaticUtility(StaticUtility storage utility) internal {
        utility.deleted = true;
    }

}
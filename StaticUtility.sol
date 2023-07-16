// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library StaticUtilities {
    struct StaticUtility {
        string name;
        string description;
        string url;
        bool deleted;
    }

    function addStaticUtility(string memory utilityName, string memory utilityDescription, string memory utilityUrl) internal pure returns (StaticUtility memory) {
        return StaticUtility({
            name: utilityName,
            description: utilityDescription,
            url: utilityUrl,
            deleted: false
        });
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
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library Utilities {
    struct Utility {
        uint256 id;
        string uri;
        uint256 remainingUses;
        uint256 expiryTimestamp; //1672444799 -> 31 December 2023
        bool deleted;
    }

    function addDynamicUtility(Utility storage utility, uint256 utilityId, string memory utilityURI, uint256 uses, uint256 utilityExpiry) internal {
        utility.id = utilityId; 
        utility.uri = utilityURI;
        utility.remainingUses = uses;
        utility.expiryTimestamp = utilityExpiry;
        utility.deleted = false;
    }

    function editDynamicUtility(Utility storage utility, string memory newURI, uint256 newUses, uint256 newExpiry) internal {
        utility.uri = newURI;
        utility.remainingUses = newUses;
        utility.expiryTimestamp = newExpiry;
    }

    function deleteDynamicUtility(Utility storage utility) internal {
        utility.deleted = true;
    }
    
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Utilities
 * @dev A library for managing utility structures within the NFTUtilities contract.
 * This library provides functions to add, edit, and delete utilities.
 */
library Utilities {
    /**
     * @dev Represents a utility with attributes like ID, URI for metadata, remaining uses, expiry timestamp, and deletion status.
     * @param id Unique identifier for this utility.
     * @param uri URI pointing to utility's metadata.
     * @param remainingUses Count of how many times this utility can be used.
     * @param expiryTimestamp Timestamp after which the utility can no longer be used. 
     * @param deleted A flag indicating whether this utility has been deleted.
     */
    struct Utility {
        uint256 id;
        string uri;
        uint256 remainingUses;
        uint256 expiryTimestamp; //1672444799 -> 31 December 2023
        bool deleted;
    }

    /**
     * @dev Initializes a new utility with the provided parameters.
     * @param utility Reference to the Utility struct to be initialized.
     * @param utilityId ID to be assigned to the new utility.
     * @param utilityURI URI pointing to the utility's metadata.
     * @param uses Number of times the utility can be used.
     * @param utilityExpiry Expiry timestamp for the utility.
     */
    function addDynamicUtility(Utility storage utility, uint256 utilityId, string memory utilityURI, uint256 uses, uint256 utilityExpiry) internal {
        utility.id = utilityId; 
        utility.uri = utilityURI;
        utility.remainingUses = uses;
        utility.expiryTimestamp = utilityExpiry;
        utility.deleted = false;
    }

    /**
     * @dev Updates the attributes of an existing utility.
     * @param utility Reference to the Utility struct to be edited.
     * @param newURI Updated URI for the utility's metadata.
     * @param newUses Updated count of how many times the utility can be used.
     * @param newExpiry Updated expiry timestamp for the utility.
     */
    function editDynamicUtility(Utility storage utility, string memory newURI, uint256 newUses, uint256 newExpiry) internal {
        utility.uri = newURI;
        utility.remainingUses = newUses;
        utility.expiryTimestamp = newExpiry;
    }

    /**
     * @dev Marks a utility as deleted.
     * @param utility Reference to the Utility struct to be deleted.
     */
    function deleteDynamicUtility(Utility storage utility) internal {
        utility.deleted = true;
    }
    
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title ERC-XXXX Non-Fungible Token Utility Standard
 * @dev See https://eips.ethereum.org for details
 * @notice This ERC provides a standard for adding utilities to NFTs
 
 * @dev This standard is a work in progress
 */

interface INFTUtilities {

     /// @dev This event is emitted when a utility is added to an NFT.
    event UtilityAdded(uint256 indexed tokenId, uint256 indexed utilityId, string utilityURI);
    
    /// @dev This event is emitted when a utility is edited for an NFT.
    event UtilityEdited(uint256 indexed tokenId, uint256 indexed utilityId, string newUtilityURI);

    /// @dev This event is emitted when a utility is deleted from an NFT.
    event UtilityDeleted(uint256 indexed tokenId, uint256 indexed utilityId);

    /**
     * @notice Function to add a utility to a set of NFTs.
     * @dev This function allows a contract owner to add a utility to a specific set of NFTs, emitting a UtilityAdded event.
     * @param tokenIds An array of token Ids that the utility should be added to.
     * @param utilityURI The data URI for the utility (IPFS hash).
     */
    function addTokenDynamicUtility(uint256[] memory tokenIds, string memory utilityURI) external;
    
    /**
     * @notice Function to add a utility to all NFTs in the collection.
     * @dev This function allows a contract owner to add a utility to all NFTs in the collection, emitting a UtilityAdded event.
     * @param utilityURI The data URI for the utility (IPFS hash).
     */
    function addDynamicUtilityToAll(string memory utilityURI) external;

    /**
     * @notice Function to edit a utility from all the associated NFTs.
     * @dev This function allows a contract owner to edit the data URI of a utility from all associated NFTs, emitting a UtilityEdited event.
     * @param utilityId The ID of the utility to be edited.
     * @param newUtilityURI The new data URI for the utility (IPFS hash).
   */
    function editDynamicUtility(uint256 utilityId, string memory newUtilityURI) external;

    /**
     * @notice Function to delete a utility from all the associated NFTs.
     * @dev This function allows a contract owner to delete a utility from all associated NFTs, emitting a UtilityDeleted event.
     * @param utilityId The ID of the utility to query.
   */
    function deleteDynamicUtility(uint256 utilityId) external;

    /**
     * @notice Function to use a specific utility of a specific NFT.
     * @dev This function allows the owner of an NFT to use a utility.
     * @param tokenId The ID of the token to query.
     * @param utilityId The ID of the utility to query.
   */
    function useUtility(uint256 tokenId, uint256 utilityId) external;

  /**
   * @notice Function to get the URI associated with a specific NFT.
   * @dev This function allows anyone to query the URI of a specific NFT.
   * @param tokenId The ID of the token to query.
   * @return string The URI of the utility.
   */
    function getTokenDynamicUtilities(uint256 tokenId) external view returns (string memory);
}

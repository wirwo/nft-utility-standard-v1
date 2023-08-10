// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "./UtilityLibrary.sol";

/**
 * @title IOwnable Interface
 * @dev Provides an interface for querying the owner of a contract and the maximum supply of its tokens.
 */
interface IOwnable {    
        function owner() external view returns (address);
        function MAX_SUPPLY() external view returns (uint256);
    }

/**
 * @title NFT Utilities
 * @dev Provides utility management for NFTs, including creating, modifying, deleting, and using utilities.
 * Ensures only NFT holders can manage utilities and provides utility querying for each token.
 */
contract NFTUtilities is AccessControl {
    using Utilities for Utilities.Utility[];
    
    IOwnable public NFT;

    struct UtilityData {
        string uri;
        uint256 remainingUses;
        uint256 expiryTimestamp;
        bool deleted;
    }

    // Mappings for utility data and tracking
    mapping(uint256 => Utilities.Utility) private _allUtilities;
    mapping(uint256 => Utilities.Utility[]) private _specificDynamicUtilities;
    mapping(uint256 => mapping(uint256 => Utilities.Utility)) private _editedUtilities;

    // Utility metadata mappings
    mapping(uint256 => uint256) private _lastUpdated;
    mapping(uint256 => uint256) private _utilityToTokenId;
    mapping(uint256 => bool) private _isUtilitySpecific;
    mapping(uint256 => uint256) private _utilityToSpecificIndex;

    // Counter to ensure unique utility IDs
    uint256 private _globalUtilityCounter = 0;

    /**
     * @dev Sets the NFT contract address and initializes utilities.
     * Requires the caller to be the owner of the NFT contract.
     * @param _NFT address of the NFT contract.
     */
    constructor(address _NFT) {
        require(IOwnable(_NFT).owner() == _msgSender(), "NFTUtilities: Deployer is not owner of the NFT contract");
        NFT = IOwnable(_NFT);
    }
    
    function _isNftHolder(address holder) private view returns (bool) {
        IERC721Enumerable token = IERC721Enumerable(address(NFT));
        uint256 balance = token.balanceOf(holder);
        if (balance > 0) {
            return true;
        }
        return false;
    }

    /**
     * @dev Adds a utility to specific tokens.
     * Only NFT holders can call this.
     * @param tokenIds list of NFT token IDs to add the utility to.
     * @param utilityURI URI of the utility's metadata.
     * @param utilityUses number of uses for the utility.
     * @param utilityExpiry expiration timestamp for the utility.
     */
    function addUtility(uint256[] memory tokenIds, string memory utilityURI, uint256 utilityUses, uint256 utilityExpiry) public {
        // Ensure caller is an NFT holder
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];

            // Ensure the token ID is within the valid range
            require(id < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");
            Utilities.Utility storage newUtility = _specificDynamicUtilities[id].push();
            Utilities.addDynamicUtility(newUtility, _globalUtilityCounter, utilityURI, utilityUses, utilityExpiry); 

            _utilityToTokenId[_globalUtilityCounter] = id;
            _utilityToSpecificIndex[_globalUtilityCounter] = _specificDynamicUtilities[id].length - 1;
            _isUtilitySpecific[_globalUtilityCounter] = true;
            _globalUtilityCounter++;
        }
    }

    /**
     * @dev Adds a utility to all tokens.
     * Only NFT holders can call this.
     * @param utilityURI URI of the utility's metadata.
     * @param utilityUses number of uses for the utility.
     * @param utilityExpiry expiration timestamp for the utility.
     */
    function addUtilityToAll(string memory utilityURI, uint256 utilityUses, uint256 utilityExpiry) public {
        // Ensure caller is an NFT holder
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");
        
        Utilities.Utility storage utility = _allUtilities[_globalUtilityCounter];
        Utilities.addDynamicUtility(utility, _globalUtilityCounter, utilityURI, utilityUses, utilityExpiry); 
        _isUtilitySpecific[_globalUtilityCounter] = false;

        _globalUtilityCounter++;
    }

    /**
     * @dev Edits a utility details.
     * Only NFT holders can call this.
     * @param utilityId ID of the utility to be edited.
     * @param newUtilityURI Updated URI of the utility's metadata.
     * @param newUses Updated number of uses for the utility.
     * @param newExpiry Updated expiration timestamp for the utility.
     */
    function editUtility(uint256 utilityId, string memory newUtilityURI, uint256 newUses, uint256 newExpiry) public {
        // Ensure caller is an NFT holder
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");
        
        if (_isUtilitySpecific[utilityId]) {
            uint256 tokenId = _utilityToTokenId[utilityId];
            uint256 index = _utilityToSpecificIndex[utilityId];
            Utilities.editDynamicUtility(_specificDynamicUtilities[tokenId][index], newUtilityURI, newUses, newExpiry);
        } else {
            Utilities.editDynamicUtility(_allUtilities[utilityId], newUtilityURI, newUses, newExpiry);
        }
        _lastUpdated[utilityId] = block.number;
    }

    /**
     * @dev Deleting a utility from collection.
     * Only NFT holders can call this.
     * @param utilityId ID of the utility to be deleted.
     */
    function deleteUtility(uint256 utilityId) public {
        // Ensure caller is an NFT holder
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");

        if (_isUtilitySpecific[utilityId]) {
            uint256 tokenId = _utilityToTokenId[utilityId];
            uint256 index = _utilityToSpecificIndex[utilityId];
            Utilities.deleteDynamicUtility(_specificDynamicUtilities[tokenId][index]);
        } else {
            Utilities.deleteDynamicUtility(_allUtilities[utilityId]);
        }
        _lastUpdated[utilityId] = block.number;
    }

    /**
     * @dev Allows the owner of an NFT to use a utility.
     * @param tokenId ID of the NFT token using the utility.
     * @param utilityId ID of the utility to be used.
     */
    function useUtility(uint256 tokenId, uint256 utilityId) public {
        // Ensure the caller owns the specified token
        address token = address(NFT);
        require(IERC721Enumerable(token).ownerOf(tokenId) == _msgSender(), "NFTUtilities: caller does not own the token");
        
        // Ensure the token ID is within the valid range
        require(tokenId < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");

        Utilities.Utility storage utility;

        if (!_isUtilitySpecific[utilityId]) {
            if (_editedUtilities[utilityId][tokenId].id != 0) {
                utility = _editedUtilities[utilityId][tokenId];
            } else {
                utility = _allUtilities[utilityId];
            }
        } else {
            uint256 specificTokenId = _utilityToTokenId[utilityId];
            require(specificTokenId == tokenId, "NFTUtilities: utility not assigned to this token");

            if (_editedUtilities[utilityId][tokenId].id != 0) {
                utility = _editedUtilities[utilityId][tokenId];
            } else {
                utility = _specificDynamicUtilities[tokenId][utilityId];
            }
        }
        require(utility.expiryTimestamp > block.timestamp, "NFTUtilities: utility has expired");
        require(!utility.deleted, "NFTUtilities: This utility has been deleted");
        require(utility.remainingUses >= 1, "NFTUtilities: no remaining uses for utility");

        utility.remainingUses--;
    }

    /**
     * @dev Retrieves utility data for a specific NFT token.
     * @param tokenId ID of the NFT token to query utilities for.
     * @return An array of utility data associated with the specified NFT token.
     */
    function getUtility(uint256 tokenId) public view returns (UtilityData[] memory) {
        uint256 totalUtilityLength = _globalUtilityCounter;
        uint256 relevantUtilityCounter = 0;

        // Ensure the token ID is within the valid range
        require(tokenId < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");

        // First pass to count relevant utilities
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                Utilities.Utility storage utility = _isUtilitySpecific[i] ? _specificDynamicUtilities[tokenId][_utilityToSpecificIndex[i]] : _allUtilities[i];

                if (_editedUtilities[i][tokenId].id != 0) {
                    utility = _editedUtilities[i][tokenId];
                }

                if (!utility.deleted) {
                    relevantUtilityCounter++;
                }
            }
        }

        UtilityData[] memory utilities = new UtilityData[](relevantUtilityCounter);

        uint256 currentUtilityIndex = 0;
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                Utilities.Utility storage utility = _isUtilitySpecific[i] ? _specificDynamicUtilities[tokenId][_utilityToSpecificIndex[i]] : _allUtilities[i];

                if (_editedUtilities[i][tokenId].id != 0) {
                    utility = _editedUtilities[i][tokenId];
                }

                if (!utility.deleted) {
                    utilities[currentUtilityIndex++] = UtilityData(utility.uri, utility.remainingUses, utility.expiryTimestamp, utility.deleted);
                }
            }
        }

        return utilities;
    }

}
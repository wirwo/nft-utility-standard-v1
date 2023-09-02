// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "./UtilityLibrary.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import "../lib/forge-std/src/console.sol";

error Utility__TokenIdNotFound();
error Utility__UtilityNotFound();
error Utility__UtilityDeleted();
error Utility__UtilityExpired();
error Utility__TokenNoHaveUtility();
error Utility__UtilityOutOfUse();

/**
 * @title IOwnable Interface
 * @dev Interface for querying the owner of a contract and the maximum supply of its tokens.
 */
interface IOwnable {
    function owner() external view returns (address);
    function MAX_SUPPLY() external view returns (uint256);
}

/**
 * @title NFT Utilities
 * @dev Contract for utility management of NFTs: creating, modifying, deleting, and using utilities.
 * Ensures only NFT holders can manage utilities and provides utility querying for each token.
 */
contract NFTUtilities is AccessControl {
    
    struct UtilityData {
        string uri;
        uint256 remainingUses;
        uint256 expiryTimestamp;
        bool deleted;
    }

    IOwnable public NFT;

    // Utility tracking and metadata mappings
    mapping(uint256 => Utilities.Utility) private _allUtilities;
    mapping(uint256 => bool) private _isUtilitySpecific;
    mapping(uint256 => bool) private _utilityIdPresent;
    mapping(uint256 => uint256[]) private _utilitiesOfToken;
    mapping(uint256 => mapping(uint256 => uint256)) private _utilityRemainingUsesOfToken;
    mapping(uint256 => mapping(uint256 => bool)) private _utilityHasBeenUsed;
    mapping(uint256 => mapping(uint256 => bool)) private _tokenHasUtility;

    // Counter to ensure unique utility IDs
    uint256 private _globalUtilityCounter = 0;

    /**
     * @dev Ensures the caller is the owner of the NFT contract and initializes the contract with the provided NFT address.
     * @param nftContract The address of the NFT contract.
     */
    constructor(address nftContract) {
        require(IOwnable(nftContract).owner() == _msgSender(), "NFTUtilities: Deployer is not owner of the NFT contract");
        NFT = IOwnable(nftContract);
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
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];

            // Ensure the token ID is within the valid range
            if(id > NFT.MAX_SUPPLY()) revert Utility__TokenIdNotFound();

            Utilities.Utility storage utility = _allUtilities[_globalUtilityCounter];
            Utilities.addDynamicUtility(utility, _globalUtilityCounter, utilityURI, utilityUses, utilityExpiry);

            _utilitiesOfToken[id].push(_globalUtilityCounter);
            _tokenHasUtility[id][_globalUtilityCounter] = true;

        }
        _isUtilitySpecific[_globalUtilityCounter] = true;
        _utilityIdPresent[_globalUtilityCounter] = true;
        _globalUtilityCounter++;
    }

    /**
     * @dev Adds a utility to all tokens.
     * Only NFT holders can call this.
     * @param utilityURI URI of the utility's metadata.
     * @param utilityUses number of uses for the utility.
     * @param utilityExpiry expiration timestamp for the utility.
     */
    function addUtilityToAll(string memory utilityURI, uint256 utilityUses, uint256 utilityExpiry) public {
        Utilities.Utility storage utility = _allUtilities[_globalUtilityCounter];
        Utilities.addDynamicUtility(utility, _globalUtilityCounter, utilityURI, utilityUses, utilityExpiry); 
        _isUtilitySpecific[_globalUtilityCounter] = false;
        _utilityIdPresent[_globalUtilityCounter] = true;
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
        if(!_utilityIdPresent[utilityId]) revert Utility__UtilityNotFound();
        Utilities.editDynamicUtility(_allUtilities[utilityId], newUtilityURI, newUses, newExpiry);
    }

    /**
     * @dev Deleting a utility from collection.
     * Only NFT holders can call this.
     * @param utilityId ID of the utility to be deleted.
     */
    function deleteUtility(uint256 utilityId) public {
        if(!_utilityIdPresent[utilityId]) revert Utility__UtilityNotFound();
        Utilities.deleteDynamicUtility(_allUtilities[utilityId]);
    }

    /**
     * @dev Allows the owner of an NFT to use a utility.
     * @param tokenId ID of the NFT token using the utility.
     * @param utilityId ID of the utility to be used.
     */
    function useUtility(uint256 tokenId, uint256 utilityId) public {
        if(_allUtilities[utilityId].deleted) revert Utility__UtilityDeleted();
        if(_allUtilities[utilityId].expiryTimestamp < block.timestamp) revert Utility__UtilityExpired();
        
        // Check if token has utilityId
        if(_isUtilitySpecific[utilityId]){
            if(!_tokenHasUtility[tokenId][utilityId]) revert Utility__TokenNoHaveUtility();
        }

        // Check if the utility's remaining uses for this token was ever initialized, if not, set it.
        if (_utilityHasBeenUsed[tokenId][utilityId] == false) {
            if(_allUtilities[utilityId].remainingUses < 1) revert Utility__UtilityOutOfUse();
            _utilityRemainingUsesOfToken[tokenId][utilityId] = _allUtilities[utilityId].remainingUses;
            _utilityHasBeenUsed[tokenId][utilityId] = true;
        }
        else{
            if(_utilityRemainingUsesOfToken[tokenId][utilityId] < 1) revert Utility__UtilityOutOfUse();
        }

        // Reduce the remaining uses by 1 for the specific tokenId
        _utilityRemainingUsesOfToken[tokenId][utilityId]--;
    }
    
    /**
     * @dev Retrieves utility data for a specific NFT token.
     * @param tokenId ID of the NFT token to query utilities for.
     * @return An array of utility data associated with the specified NFT token.
     */
    function getUtility(uint256 tokenId) public view returns (UtilityData[] memory) {
        if(tokenId > NFT.MAX_SUPPLY()) revert Utility__TokenIdNotFound();

        // Create an array that is long enough to hold both specific and global utilities
        UtilityData[] memory utilities = new UtilityData[](_globalUtilityCounter);
        uint256 currentIndex = 0;

        // Populate specific utilities
        for (uint256 i = 0; i < _utilitiesOfToken[tokenId].length; i++) {
            uint256 utilityId = _utilitiesOfToken[tokenId][i];
            if (!_allUtilities[utilityId].deleted) {
                uint256 remainingUses = _allUtilities[utilityId].remainingUses;
            
                // If the utility's remaining uses for this token were modified, get that value
                if (_utilityHasBeenUsed[tokenId][utilityId] == true) {
                    remainingUses = _utilityRemainingUsesOfToken[tokenId][utilityId];
                }

                utilities[currentIndex] = UtilityData(_allUtilities[utilityId].uri, remainingUses, _allUtilities[utilityId].expiryTimestamp, _allUtilities[utilityId].deleted);
                currentIndex++;
            }
        }

        // Populate global utilities
        for (uint256 i = 0; i < _globalUtilityCounter; i++) {
            if (!_allUtilities[i].deleted && !_isUtilitySpecific[i]) {
                uint256 remainingUses = _allUtilities[i].remainingUses;
                // If the utility's remaining uses for this token were modified, get that value
                if (_utilityHasBeenUsed[tokenId][i] == true) {
                    remainingUses = _utilityRemainingUsesOfToken[tokenId][i];
                }
                
                utilities[currentIndex] = UtilityData(_allUtilities[i].uri, remainingUses, _allUtilities[i].expiryTimestamp, _allUtilities[i].deleted);
                currentIndex++;
            }
        }

        // Resize utilities array to return
        UtilityData[] memory utilitiesPreview = new UtilityData[](currentIndex);
        for(uint256 i = 0; i < currentIndex; i++) {
            utilitiesPreview[i] = utilities[i];
        }

        return utilitiesPreview;
    }
	
}
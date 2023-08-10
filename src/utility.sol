// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "./UtilityLibrary.sol";

interface IOwnable {    
        function owner() external view returns (address);
        function MAX_SUPPLY() external view returns (uint256);
    }

contract NFTUtilities is AccessControl {
    using Utilities for Utilities.Utility[];
    
    IOwnable public NFT;

    struct UtilityData {
        string uri;
        uint256 remainingUses;
        uint256 expiryTimestamp;
        bool deleted;
    }

    // Utility Mappings
    mapping(uint256 => Utilities.Utility) private _allUtilities;
    mapping(uint256 => Utilities.Utility[]) private _specificDynamicUtilities;
    mapping(uint256 => mapping(uint256 => Utilities.Utility)) private _editedUtilities;

    // Mappings for utility tracking and identification
    mapping(uint256 => uint256) private _lastUpdated;
    mapping(uint256 => uint256) private _utilityToTokenId;
    mapping(uint256 => bool) private _isUtilitySpecific;
    mapping(uint256 => uint256) private _utilityToSpecificIndex;

    // Utility counter
    uint256 private _globalUtilityCounter = 0;

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

    function addUtility(uint256[] memory tokenIds, string memory utilityURI, uint256 uses, uint256 utilityExpiry) public {
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(id < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");
            Utilities.Utility storage newUtility = _specificDynamicUtilities[id].push();
            Utilities.addDynamicUtility(newUtility, _globalUtilityCounter, utilityURI, uses, utilityExpiry); 

            _utilityToTokenId[_globalUtilityCounter] = id;
            _utilityToSpecificIndex[_globalUtilityCounter] = _specificDynamicUtilities[id].length - 1;
            _isUtilitySpecific[_globalUtilityCounter] = true;
            _globalUtilityCounter++;
        }
    }

    function addUtilityToAll(string memory utilityURI, uint256 uses, uint256 utilityExpiry) public {
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");
        
        Utilities.Utility storage utility = _allUtilities[_globalUtilityCounter];
        Utilities.addDynamicUtility(utility, _globalUtilityCounter, utilityURI, uses, utilityExpiry); 
        _isUtilitySpecific[_globalUtilityCounter] = false;

        _globalUtilityCounter++;
    }

    function editUtility(uint256 utilityId, string memory newUtilityURI, uint256 newUses, uint256 newExpiry) public {
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

    function deleteUtility(uint256 utilityId) public {
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


    function useUtility(uint256 tokenId, uint256 utilityId) public {
        address token = address(NFT);
        require(IERC721Enumerable(token).ownerOf(tokenId) == _msgSender(), "NFTUtilities: caller does not own the token");
        require(tokenId < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");

        Utilities.Utility storage utility;

        if (!_isUtilitySpecific[utilityId]) {
            // The utility is from _allUtilities
            if (_editedUtilities[utilityId][tokenId].id != 0) {
                utility = _editedUtilities[utilityId][tokenId];
            } else {
                utility = _allUtilities[utilityId];
            }
        } else {
            // The utility is from _specificDynamicUtilities
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

    function getUtility(uint256 tokenId) public view returns (UtilityData[] memory) {
        uint256 totalUtilityLength = _globalUtilityCounter;
        uint256 relevantUtilityCounter = 0;
        require(tokenId < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");
        // First pass to count relevant utilities
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                // If the utility is global or it is specific to this token
                Utilities.Utility storage utility = _isUtilitySpecific[i] ? _specificDynamicUtilities[tokenId][_utilityToSpecificIndex[i]] : _allUtilities[i];

                // If the utility has been edited for this token
                if (_editedUtilities[i][tokenId].id != 0) {
                    utility = _editedUtilities[i][tokenId];
                }

                if (!utility.deleted) {
                    relevantUtilityCounter++;
                }
            }
        }

        // Now create an array with the correct size
        UtilityData[] memory utilities = new UtilityData[](relevantUtilityCounter);

        // Second pass to fill the new array
        uint256 currentUtilityIndex = 0;
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                // If the utility is global or it is specific to this token
                Utilities.Utility storage utility = _isUtilitySpecific[i] ? _specificDynamicUtilities[tokenId][_utilityToSpecificIndex[i]] : _allUtilities[i];

                // If the utility has been edited for this token
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
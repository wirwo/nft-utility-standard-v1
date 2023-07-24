// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "./DynamicUtility.sol";

interface IOwnable {    
        function owner() external view returns (address);
        function MAX_SUPPLY() external view returns (uint256);
    }

contract NFTUtilities is AccessControl {
    using DynamicUtilities for DynamicUtilities.DynamicUtility[];
    
    IOwnable public NFT;

    struct DynamicUtilityData {
        string name;
        string description;
        string image;
        string url;
        uint256 remainingUses;
        uint256 expiryTimestamp;
        bool deleted;
    }

    // Utility Mappings
    mapping(uint256 => DynamicUtilities.DynamicUtility) private _allDynamicUtilities;
    mapping(uint256 => DynamicUtilities.DynamicUtility[]) private _specificDynamicUtilities;
    mapping(uint256 => mapping(uint256 => DynamicUtilities.DynamicUtility)) private _editedUtilities;

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

    function addTokenDynamicUtility(uint256[] memory tokenIds, string memory utilityName, string memory utilityDescription, string memory utilityImage, string memory utilityUrl, uint256 uses, uint256 utilityExpiry) public {
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(id < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");
            DynamicUtilities.DynamicUtility storage newUtility = _specificDynamicUtilities[id].push();
            DynamicUtilities.addDynamicUtilityToAll(newUtility, _globalUtilityCounter, utilityName, utilityDescription, utilityImage, utilityUrl, uses, utilityExpiry); 

            _utilityToTokenId[_globalUtilityCounter] = id;
            _utilityToSpecificIndex[_globalUtilityCounter] = _specificDynamicUtilities[id].length - 1;
            _isUtilitySpecific[_globalUtilityCounter] = true;
            _globalUtilityCounter++;
        }
    }

    function addDynamicUtilityToAll(string memory utilityName, string memory utilityDescription, string memory utilityImage, string memory utilityUrl, uint256 uses, uint256 utilityExpiry) public {
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");
        
        DynamicUtilities.DynamicUtility storage utility = _allDynamicUtilities[_globalUtilityCounter];
        DynamicUtilities.addDynamicUtilityToAll(utility, _globalUtilityCounter, utilityName, utilityDescription, utilityImage, utilityUrl, uses, utilityExpiry); 
        _isUtilitySpecific[_globalUtilityCounter] = false;

        _globalUtilityCounter++;
    }

    function editDynamicUtility(uint256 utilityId, string memory newUtilityName, string memory newUtilityDescription, string memory newImage, string memory newUrl, uint256 newUses, uint256 newExpiry) public {
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");
        if (_isUtilitySpecific[utilityId]) {
            uint256 tokenId = _utilityToTokenId[utilityId];
            uint256 index = _utilityToSpecificIndex[utilityId];
            DynamicUtilities.editDynamicUtility(_specificDynamicUtilities[tokenId][index], newUtilityName, newUtilityDescription, newImage, newUrl, newUses, newExpiry);
        } else {
            DynamicUtilities.editDynamicUtility(_allDynamicUtilities[utilityId], newUtilityName, newUtilityDescription, newImage, newUrl, newUses, newExpiry);
        }
        _lastUpdated[utilityId] = block.number;
    }

    function deleteDynamicUtility(uint256 utilityId) public {
        require(_isNftHolder(_msgSender()), "NFTUtilities: must be a holder to add utility");
        if (_isUtilitySpecific[utilityId]) {
            uint256 tokenId = _utilityToTokenId[utilityId];
            uint256 index = _utilityToSpecificIndex[utilityId];
            DynamicUtilities.deleteDynamicUtility(_specificDynamicUtilities[tokenId][index]);
        } else {
            DynamicUtilities.deleteDynamicUtility(_allDynamicUtilities[utilityId]);
        }
        _lastUpdated[utilityId] = block.number;
    }


    function useUtility(uint256 tokenId, uint256 utilityId) public {
        address token = address(NFT);
        require(IERC721Enumerable(token).ownerOf(tokenId) == _msgSender(), "NFTUtilities: caller does not own the token");
        require(tokenId < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");

        DynamicUtilities.DynamicUtility storage utility;

        if (!_isUtilitySpecific[utilityId]) {
            // The utility is from _allDynamicUtilities
            if (_editedUtilities[utilityId][tokenId].id != 0) {
                utility = _editedUtilities[utilityId][tokenId];
            } else {
                utility = _allDynamicUtilities[utilityId];
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

    function getTokenDynamicUtilities(uint256 tokenId) public view returns (DynamicUtilityData[] memory) {
        uint256 totalUtilityLength = _globalUtilityCounter;
        uint256 relevantUtilityCounter = 0;
        require(tokenId < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");
        // First pass to count relevant utilities
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                // If the utility is global or it is specific to this token
                DynamicUtilities.DynamicUtility storage utility = _isUtilitySpecific[i] ? _specificDynamicUtilities[tokenId][_utilityToSpecificIndex[i]] : _allDynamicUtilities[i];

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
        DynamicUtilityData[] memory utilities = new DynamicUtilityData[](relevantUtilityCounter);

        // Second pass to fill the new array
        uint256 currentUtilityIndex = 0;
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                // If the utility is global or it is specific to this token
                DynamicUtilities.DynamicUtility storage utility = _isUtilitySpecific[i] ? _specificDynamicUtilities[tokenId][_utilityToSpecificIndex[i]] : _allDynamicUtilities[i];

                // If the utility has been edited for this token
                if (_editedUtilities[i][tokenId].id != 0) {
                    utility = _editedUtilities[i][tokenId];
                }

                if (!utility.deleted) {
                    utilities[currentUtilityIndex++] = DynamicUtilityData(utility.name, utility.description, utility.image, utility.url, utility.remainingUses, utility.expiryTimestamp, utility.deleted);
                }
            }
        }

        return utilities;
    }

}

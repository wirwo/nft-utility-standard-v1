// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DynamicUtility.sol";
import "./StaticUtility.sol";

interface IOwnable {
        function owner() external view returns (address);
        function MAX_SUPPLY() external view returns (uint256);

    }

contract NFTUtilities is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    IOwnable public NFT;

    using DynamicUtilities for DynamicUtilities.DynamicUtility[];
    using StaticUtilities for StaticUtilities.StaticUtility[];

    //Dynamic Utility Mappings
    mapping(uint256 => DynamicUtilities.DynamicUtility) private _allDynamicUtilities;
    uint256 private _dynamicUtilityCounter = 0;

    mapping(uint256 => DynamicUtilities.DynamicUtility[]) private _specificDynamicUtilities;
    uint256 private _specificDynamicUtilityCounter = 0;

    mapping(uint256 => mapping(uint256 => DynamicUtilities.DynamicUtility)) private _editedUtilities;

    //Static Utility Mappings
    mapping(uint256 => StaticUtilities.StaticUtility) private _allStaticUtilities;
    uint256 private _staticUtilityCounter = 0;

    mapping(uint256 => StaticUtilities.StaticUtility[]) private _specificStaticUtilities;
    uint256 private _specificStaticUtilityCounter = 0;

    mapping(uint256 => mapping(uint256 => StaticUtilities.StaticUtility)) private _editedStaticUtilities;


    mapping(uint256 => uint256) private _lastUpdated;
    mapping(uint256 => mapping(uint256 => uint256)) private _lastChecked;
    
    uint256 private _globalUtilityCounter = 0;
    mapping(uint256 => uint256) private _utilityToTokenId;
    mapping(uint256 => bool) private _isUtilitySpecific;
    mapping(uint256 => uint256) private _utilityToSpecificIndex;


    constructor(address _NFT) {
        require(IOwnable(_NFT).owner() == _msgSender(), "NFTUtilities: Deployer is not owner of the NFT contract");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        NFT = IOwnable(_NFT);
    }

    function addAdmin(address newAdmin) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add a new admin");
        grantRole(ADMIN_ROLE, newAdmin);
    }


    //Start of Static Functions
    function addTokenDynamicUtility(uint256[] memory tokenIds, string memory utilityName, string memory utilityDescription, uint256 uses) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(id < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");
            DynamicUtilities.DynamicUtility storage newUtility = _specificDynamicUtilities[id].push();
            newUtility.id = _globalUtilityCounter;
            newUtility.name = utilityName;
            newUtility.description = utilityDescription;
            newUtility.remainingUses = uses;
            newUtility.deleted = false;
            _utilityToTokenId[_globalUtilityCounter] = id;
            _utilityToSpecificIndex[_globalUtilityCounter] = _specificDynamicUtilities[id].length - 1;
            _isUtilitySpecific[_globalUtilityCounter] = true;
            _globalUtilityCounter++;
        }
        _dynamicUtilityCounter++;
    }


    function addDynamicUtilityToAll(string memory utilityName, string memory utilityDescription, uint256 uses) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");
        
        DynamicUtilities.DynamicUtility storage utility = _allDynamicUtilities[_dynamicUtilityCounter];
        DynamicUtilities.addDynamicUtilityToAll(utility, _globalUtilityCounter, utilityName, utilityDescription, uses); 
        _isUtilitySpecific[_globalUtilityCounter] = false;

        _globalUtilityCounter++;
        _dynamicUtilityCounter++;
    }

    function editDynamicUtility(uint256 utilityId, string memory newUtilityName, string memory newUtilityDescription, uint256 newUses) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to edit utility");
        if (_isUtilitySpecific[utilityId]) {
            uint256 tokenId = _utilityToTokenId[utilityId];
            uint256 index = _utilityToSpecificIndex[utilityId];
            DynamicUtilities.editDynamicUtility(_specificDynamicUtilities[tokenId][index], newUtilityName, newUtilityDescription, newUses);
        } else {
            DynamicUtilities.editDynamicUtility(_allDynamicUtilities[utilityId], newUtilityName, newUtilityDescription, newUses);
        }
        _lastUpdated[utilityId] = block.number;
    }


    
    function deleteDynamicUtility(uint256 utilityId) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to delete utility");
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

        require(!utility.deleted, "NFTUtilities: This utility has been deleted");
        require(utility.remainingUses >= 1, "NFTUtilities: no remaining uses for utility");

        utility.remainingUses--;
    }


    struct UtilityData {
        string name;
        string description;
        uint256 remainingUses;
        bool deleted;
    }

    function getTokenDynamicUtilities(uint256 tokenId) public view returns (UtilityData[] memory) {
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
        UtilityData[] memory utilities = new UtilityData[](relevantUtilityCounter);

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
                    utilities[currentUtilityIndex++] = UtilityData(utility.name, utility.description, utility.remainingUses, utility.deleted);
                }
            }
        }

        return utilities;
    }

    //Start of Static Functions
    function addTokenStaticUtility(uint256[] memory tokenIds, string memory utilityName, string memory utilityDescription, string memory utilityUrl) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(id < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");
            StaticUtilities.StaticUtility storage newUtility = _specificStaticUtilities[id].push();
            newUtility.name = utilityName;
            newUtility.description = utilityDescription;
            newUtility.url = utilityUrl;
            newUtility.deleted = false;
            _utilityToTokenId[_globalUtilityCounter] = id;
            _utilityToSpecificIndex[_globalUtilityCounter] = _specificStaticUtilities[id].length - 1;
            _isUtilitySpecific[_globalUtilityCounter] = true;
            _globalUtilityCounter++;
        }
        _staticUtilityCounter++;
    }

    function addStaticUtilityToAll(string memory utilityName, string memory utilityDescription, string memory utilityUrl) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");

        StaticUtilities.StaticUtility storage utility = _allStaticUtilities[_staticUtilityCounter];
        StaticUtilities.addStaticUtilityToAll(utility, _globalUtilityCounter, utilityName, utilityDescription, utilityUrl); 
        _isUtilitySpecific[_globalUtilityCounter] = false;

        _globalUtilityCounter++;
        _staticUtilityCounter++;
    }

    function editStaticUtility(uint256 utilityId, string memory newUtilityName, string memory newUtilityDescription, string memory newUtilityUrl) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to edit utility");

        if (_isUtilitySpecific[utilityId]) {
            uint256 tokenId = _utilityToTokenId[utilityId];
            uint256 index = _utilityToSpecificIndex[utilityId];
            StaticUtilities.editStaticUtility(_specificStaticUtilities[tokenId][index], newUtilityName, newUtilityDescription, newUtilityUrl);
        } else {
            StaticUtilities.editStaticUtility(_allStaticUtilities[utilityId], newUtilityName, newUtilityDescription, newUtilityUrl);
        }
        _lastUpdated[utilityId] = block.number;
    }

    function deleteStaticUtility(uint256 utilityId) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to delete utility");

        if (_isUtilitySpecific[utilityId]) {
            uint256 tokenId = _utilityToTokenId[utilityId];
            uint256 index = _utilityToSpecificIndex[utilityId];
            StaticUtilities.deleteStaticUtility(_specificStaticUtilities[tokenId][index]);
        } else {
            StaticUtilities.deleteStaticUtility(_allStaticUtilities[utilityId]);
        }
        _lastUpdated[utilityId] = block.number;
    }

    struct UtilityData1 {
            uint256 id;
            string name;
            string description;
            string url;
            bool deleted;
        }
    
    function getTokenStaticUtilities(uint256 tokenId) public view returns (UtilityData1[] memory) {
        uint256 totalUtilityLength = _globalUtilityCounter;
        uint256 relevantUtilityCounter = 0;
        require(tokenId < NFT.MAX_SUPPLY(), "NFTUtilities: tokenId exceeds total supply");

        // First pass to count relevant utilities
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                StaticUtilities.StaticUtility storage utility = _isUtilitySpecific[i] ? _specificStaticUtilities[tokenId][_utilityToSpecificIndex[i]] : _allStaticUtilities[i];

                // If the utility has been edited for this token
                if (_editedStaticUtilities[i][tokenId].id != 0) {
                    utility = _editedStaticUtilities[i][tokenId];
                }

                if (!utility.deleted) {
                    relevantUtilityCounter++;
                }
            }
        }

        // Now create an array with the correct size
        UtilityData1[] memory utilities = new UtilityData1[](relevantUtilityCounter);

        // Second pass to fill the new array
        uint256 currentUtilityIndex = 0;
        for (uint256 i = 0; i < totalUtilityLength; i++) {
            if (!_isUtilitySpecific[i] || _utilityToTokenId[i] == tokenId) {
                StaticUtilities.StaticUtility storage utility = _isUtilitySpecific[i] ? _specificStaticUtilities[tokenId][_utilityToSpecificIndex[i]] : _allStaticUtilities[i];

                // If the utility has been edited for this token
                if (_editedStaticUtilities[i][tokenId].id != 0) {
                    utility = _editedStaticUtilities[i][tokenId];
                }

                if (!utility.deleted) {
                    utilities[currentUtilityIndex].id = i;
                    utilities[currentUtilityIndex].name = utility.name;
                    utilities[currentUtilityIndex].description = utility.description;
                    utilities[currentUtilityIndex].url = utility.url;
                    currentUtilityIndex++;
                }
            }
        }

        return utilities;
    }


}

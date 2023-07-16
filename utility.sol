// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DynamicUtility.sol";
import "./StaticUtility.sol";

interface IOwnable {
        function owner() external view returns (address);
    }


contract NFTUtilities is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    IOwnable public NFT;

    using DynamicUtilities for DynamicUtilities.DynamicUtility[];
    using StaticUtilities for StaticUtilities.StaticUtility[];

    mapping(address => mapping(uint256 => DynamicUtilities.DynamicUtility[])) private _tokenDynamicUtilities;
    mapping(address => mapping(uint256 => StaticUtilities.StaticUtility[])) private _tokenStaticUtilities;
    mapping(uint256 => uint256[]) private dynamicUtilityToTokens;
    mapping(uint256 => uint256[]) private staticUtilityToTokens;
    mapping(uint256 => address) private dynamicUtilityToToken;
    mapping(uint256 => address) private staticUtilityToToken;


    event UtilityUsed(address indexed user, address indexed token, uint256 indexed tokenId, uint256 utilityIndex);

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

    function addTokenDynamicUtility(uint256[] memory tokenIds, string memory utilityName, string memory utilityDescription, uint256 uses) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");

        address token = address(NFT);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenDynamicUtilities[token][tokenIds[i]].addDynamicUtility(utilityName, utilityDescription, uses);
        }
    }

    function addDynamicUtilityToAll(string memory utilityName, string memory utilityDescription, uint256 uses) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");

        address token = address(NFT);
        uint256 supply = IERC721Enumerable(token).totalSupply();

        for (uint256 i = 1; i <= supply; i++) {
            _tokenDynamicUtilities[token][i].addDynamicUtility(utilityName, utilityDescription, uses);

        }
    }

    function addTokenStaticUtility(uint256[] memory tokenIds, string memory utilityName, string memory utilityDescription, string memory utilityUrl) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");

        address token = address(NFT);  

        StaticUtilities.StaticUtility memory staticUtility = StaticUtilities.addStaticUtility(utilityName, utilityDescription, utilityUrl);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenStaticUtilities[token][tokenIds[i]].push(staticUtility);

            uint256 utilityIndex = _tokenStaticUtilities[token][tokenIds[i]].length - 1;

            staticUtilityToTokens[utilityIndex].push(i);
            staticUtilityToToken[utilityIndex] = token;
        }
    }

    function addStaticUtilityToAll(string memory utilityName, string memory utilityDescription, string memory utilityUrl) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to add utility");
            
        address token = address(NFT);  
        uint256 supply = IERC721Enumerable(token).totalSupply();

        StaticUtilities.StaticUtility memory staticUtility = StaticUtilities.addStaticUtility(utilityName, utilityDescription, utilityUrl);

        for (uint256 i = 1; i <= supply; i++) {
            _tokenStaticUtilities[token][i].push(staticUtility);

            uint256 utilityIndex = _tokenStaticUtilities[token][i].length - 1;

            staticUtilityToTokens[utilityIndex].push(i);
            staticUtilityToToken[utilityIndex] = token;
        }
    }

    function editDynamicUtilityFromAll(uint256 utilityId, string memory newUtilityName, string memory newUtilityDescription, uint256 newUses) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to edit utility");

        address token = dynamicUtilityToToken[utilityId];
        uint256[] memory tokenIds = dynamicUtilityToTokens[utilityId];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _tokenDynamicUtilities[token][tokenId][utilityId].name = newUtilityName;
            _tokenDynamicUtilities[token][tokenId][utilityId].description = newUtilityDescription;
            _tokenDynamicUtilities[token][tokenId][utilityId].remainingUses = newUses;
        }
    }       

    function editStaticUtilityFromAll(uint256 utilityId, string memory newUtilityName, string memory newUtilityDescription, string memory newUrl) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to edit utility");

        address token = staticUtilityToToken[utilityId];
        uint256[] memory tokenIds = staticUtilityToTokens[utilityId];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _tokenStaticUtilities[token][tokenId][utilityId].name = newUtilityName;
            _tokenStaticUtilities[token][tokenId][utilityId].description = newUtilityDescription;
            _tokenStaticUtilities[token][tokenId][utilityId].url = newUrl;
        }
    }       

    function deleteDynamicUtilityFromAll(uint256 utilityId) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to delete utility");

        address token = dynamicUtilityToToken[utilityId];
        uint256[] memory tokenIds = dynamicUtilityToTokens[utilityId];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _tokenDynamicUtilities[token][tokenId][utilityId].deleted = true;
        }
    }

    function deleteStaticUtilityFromAll(uint256 utilityId) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NFTUtilities: must have admin role to delete utility");

        address token = staticUtilityToToken[utilityId];
        uint256[] memory tokenIds = staticUtilityToTokens[utilityId];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _tokenStaticUtilities[token][tokenId][utilityId].deleted = true;
        }
    }

    function useUtility(uint256 tokenId, uint256 utilityIndex) public {
        address token = address(NFT);  
        require(!_tokenDynamicUtilities[token][tokenId][utilityIndex].isUsed[_msgSender()], "NFTUtilities: utility already used");
        require(_tokenDynamicUtilities[token][tokenId][utilityIndex].remainingUses > 0, "NFTUtilities: no remaining uses for utility");
        require(IERC721Enumerable(token).ownerOf(tokenId) == _msgSender(), "NFTUtilities: caller does not own the token");
        _tokenDynamicUtilities[token][tokenId][utilityIndex].isUsed[_msgSender()] = true;
        _tokenDynamicUtilities[token][tokenId][utilityIndex].remainingUses--;
        emit UtilityUsed(_msgSender(), token, tokenId, utilityIndex);
    }

    function getTokenDynamicUtilities(uint256 tokenId) public view returns (string[] memory, string[] memory, uint256[] memory, bool[] memory) {
        address token = address(NFT);  
        DynamicUtilities.DynamicUtility[] storage utilities = _tokenDynamicUtilities[token][tokenId];
        uint256 length = utilities.length;
        string[] memory names = new string[](length);
        string[] memory descriptions = new string[](length);
        uint256[] memory remainingUses = new uint256[](length);
        bool[] memory deleted = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            names[i] = utilities[i].name;
            descriptions[i] = utilities[i].description;
            remainingUses[i] = utilities[i].remainingUses;
            deleted[i] = utilities[i].deleted;
        }

        return (names, descriptions, remainingUses, deleted);
    }


    function getTokenStaticUtilities(uint256 tokenId) public view returns (string[] memory, string[] memory, string[] memory, bool[] memory) {
        address token = address(NFT);  
        StaticUtilities.StaticUtility[] storage utilities = _tokenStaticUtilities[token][tokenId];
        uint256 length = utilities.length;
        
        string[] memory names = new string[](length);
        string[] memory descriptions = new string[](length);
        string[] memory url = new string[](length);
        bool[] memory deleted = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            names[i] = utilities[i].name;
            descriptions[i] = utilities[i].description;
            url[i] = utilities[i].url;
            deleted[i] = utilities[i].deleted;
        }

        return (names, descriptions, url, deleted);
    }
}

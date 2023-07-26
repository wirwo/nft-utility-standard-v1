// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {NFTUtilities} from "./utility.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";

contract UtilityProposal is AccessControl{

    NFTUtilities public nftUtilitiesInstance;
    address private NFTAddress;


    constructor(address _nftUtilitiesAddress, address _NFTAddress) {
        nftUtilitiesInstance = NFTUtilities(_nftUtilitiesAddress);
        NFTAddress = _NFTAddress;
    }

    struct Proposal {
        address proposer;
        uint256[] tokenIds;
        string utilityName;
        string utilityDescription;
        string utilityImage;
        string utilityUrl;
        uint256 uses;
        uint256 utilityExpiry;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalStatus status;
        bool isForAllTokens;
    }
    enum ProposalStatus { Pending, Executed, Deleted }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public votes;

    function _isNftHolder(address holder) private view returns (bool) {
        IERC721Enumerable token = IERC721Enumerable(address(NFTAddress));
        uint256 balance = token.balanceOf(holder);
        if (balance > 0) {
            return true;
        }
        return false;
    }

    function proposeUtility(
        uint256[] memory tokenIds,
        string memory utilityName,
        string memory utilityDescription,
        string memory utilityImage,
        string memory utilityUrl,
        uint256 uses,
        uint256 utilityExpiry
    ) public {
        require(
            _isNftHolder(_msgSender()),
            "NFTUtilities: must be a holder to propose utility"
        );

        proposals[proposalCount++] = Proposal(
            _msgSender(),
            tokenIds,
            utilityName,
            utilityDescription,
            utilityImage, 
            utilityUrl, 
            uses,
            utilityExpiry,
            0,
            0,
            ProposalStatus.Pending,
            false
        );
    }

    function proposeUtilityToAll(
        string memory utilityName,
        string memory utilityDescription,
        string memory utilityImage,
        string memory utilityUrl,
        uint256 utilityExpiry,
        uint256 uses
    ) public {
        require(
            _isNftHolder(_msgSender()),
            "NFTUtilities: must be a holder to propose utility"
        );

        proposals[proposalCount++] = Proposal(
            _msgSender(),
            new uint256[](0), // No specific tokenIds
            utilityName,
            utilityDescription,
            utilityImage,
            utilityUrl,
            uses,
            utilityExpiry,
            0,
            0,
            ProposalStatus.Pending,
            true
        );
    }

    function vote(uint256 proposalId, bool support) public {
        require(
            _isNftHolder(_msgSender()),
            "NFTUtilities: must be a holder to vote"
        );
        require(
            !votes[proposalId][_msgSender()],
            "NFTUtilities: cannot vote more than once"
        );

        Proposal storage proposal = proposals[proposalId];

        if (support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }

        votes[proposalId][_msgSender()] = true;
    }

    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.status == ProposalStatus.Executed,
            "NFTUtilities: proposal already executed"
        );
        require(
            proposal.forVotes > proposal.againstVotes && proposal.forVotes >= 5,
            "NFTUtilities: not enough votes to execute proposal"
        );

        if (proposal.isForAllTokens) {
            nftUtilitiesInstance.addDynamicUtilityToAll(
                proposal.utilityName,
                proposal.utilityDescription,
                proposal.utilityImage,
                proposal.utilityUrl,
                proposal.utilityExpiry, 
                proposal.uses
            );
        } else {
            nftUtilitiesInstance.addTokenDynamicUtility(
                proposal.tokenIds,
                proposal.utilityName,
                proposal.utilityDescription,
                proposal.utilityImage,
                proposal.utilityUrl,
                proposal.utilityExpiry, 
                proposal.uses
            );
        }

        proposal.status = ProposalStatus.Executed;
    }

    function deleteProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.status == ProposalStatus.Pending,
            "NFTUtilities: Can only delete pending proposals"
        );
        require(
            proposal.proposer == _msgSender(),
            "NFTUtilities: Only the proposer can delete the proposal"
        );
        
        proposal.status = ProposalStatus.Deleted;
    }

    function cancelProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.againstVotes >= 5,
            "NFTUtilities: not enough votes to cancel proposal"
        );

        proposal.status = ProposalStatus.Deleted;
    }

    function getAllProposals() public view returns (Proposal[] memory) {
        Proposal[] memory proposalList = new Proposal[](proposalCount);
        for (uint256 i = 0; i < proposalCount; i++) {
            proposalList[i] = proposals[i];
        }
        return proposalList;
    }

}
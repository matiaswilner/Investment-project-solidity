//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./Proposal.sol";

contract SmartInvestment {

    enum SystemState { Closed, Proposal, Voting }
    SystemState public systemState;

    uint256 proposalIdsCounter = 1;
    uint256 ownerIdsCounter = 1;
    uint256 makerIdsCounter = 1;
    uint256 auditorIdsCounter = 1;
    uint256 voterIdsCounter = 1;

    mapping(uint256 => address) public proposals;
    mapping(address => Owner) public owners;
    mapping(address => Maker) public makers;
    mapping(address => Auditor) public auditors;
    mapping(address => Voter) public voters;

    struct Owner {
        uint256 id;
    }

    struct Maker {
        uint256 id;
        string name;
        string country;
        string passportNumber;
    }

    struct Auditor {
        uint256 id;
    }

    struct Voter {
        uint256 id;
    }

    modifier isOwner() {
        require(owners[msg.sender].id != 0);
        _;
    }

    modifier isAuditor() {
        require(auditors[msg.sender].id != 0);
        _;
    }

    modifier isMaker() {
        require(makers[msg.sender].id != 0);
        _;
    }

    /*
        REQUERIMIENTO ROLES 8 Y 9
    */
    modifier enableProposal() {
        require(makerIdsCounter >= 3 && auditorIdsCounter >= 2);
        _;
    }

    constructor() {
        owners[msg.sender] = Owner(ownerIdsCounter);
        ownerIdsCounter++;
        systemState = SystemState.Closed;
    }

    /*
        REQUERIMIENTO ROLES 5
        Solo un owner puede agregar otro owner, entonces
        debemos usar el modifier isOwner.
    */
    function addOwner(address newOwnerAddress) public isOwner {
        owners[newOwnerAddress] = Owner(ownerIdsCounter);
        ownerIdsCounter++;
    }

    /*
        REQUERIMIENTO ROLES 6
        Solo los owners podrán registrar makers, entonces
        debemos usar el modifier isOwner
    */
    function addMaker(address newMakerAddress, string memory name, string memory country, string memory passportNumber) public isOwner {
        makers[newMakerAddress] = Maker(makerIdsCounter, name, country, passportNumber);
        makerIdsCounter++;
    }

    function switchState() public isOwner {
        if (systemState == SystemState.Proposal) {
            setStateVoting();
        } else if (systemState == SystemState.Closed) {
            setStateProposal();
        } else if (systemState == SystemState.Voting) {
            setStateClosed();
        } else {
            assert(false);
        }
    }

    /*
        REQUERIMIENTO PROPUESTAS 2, 4
    */
    function setStateVoting() internal {
        uint256 lastProposalId = proposalIdsCounter - 1;
        uint256 lastProposalId2 = lastProposalId - 1;
        if (lastProposalId > 0 && lastProposalId2 > 0) {
            Proposal proposal1 = Proposal(proposals[lastProposalId]);
            Proposal proposal2 = Proposal(proposals[lastProposalId2]);
            if (proposal1.getIsOpen() && proposal2.getIsOpen()) {
                // 🤔 Hay q cerrar las dos propuestas??
                systemState = SystemState.Voting;
            }
            else {
                assert(false);
            }
        }
        else {
            assert(false);
        }
    }

    /*
        REQUERIMIENTO PROPUESTAS 1, 3
    */
    function setStateProposal() internal enableProposal {
        systemState = SystemState.Proposal;
    }

    function setStateClosed() internal {
        // TODO
    }

    /*
        REQUERIMIENTO PROPUESTAS 7
    */
    function validateProposal(uint256 proposalId) public isAuditor {
        if (proposals[proposalId] != address(0)) {    // Proposal existe
            Proposal(proposals[proposalId]).setAudited();
        }
    }

    /*
        REQUERIMIENTO ROLES 7
    */
    function createProposal(string memory name, string memory description, uint256 minimumInvestment) public isMaker {
        if (systemState == SystemState.Proposal) {
            proposals[proposalIdsCounter] = new Proposal(proposalIdsCounter, false, false, name, description, minimumInvestment, makers[msg.sender].id);
            proposalIdsCounter++;
            
        } else {
            assert(false);
        }
        
    }

}
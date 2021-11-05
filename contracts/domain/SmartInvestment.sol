//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract SmartInvestment {

    enum SystemState { Closed, Proposal, Voting }
    SystemState public systemState;

    uint256 proposalIdsCounter = 1;
    uint256 ownerIdsCounter = 1;
    uint256 makerIdsCounter = 1;
    uint256 auditorIdsCounter = 1;
    uint256 voterIdsCounter = 1;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => Owner) public owners;
    mapping(address => Maker) public makers;
    mapping(address => Auditor) public auditors;
    mapping(address => Voter) public voters;

    struct Owner {
        uint256 id;
    }

    struct Maker {
        uint256 id;
    }

    struct Auditor {
        uint256 id;
    }

    struct Voter {
        uint256 id;
    }

    /*
        REQUERIMIENTO PROPUESTAS 6
    */
    struct Proposal {
        uint256 id;
        bool isOpen;
        bool audited;
        string name;
        string description;
        uint256 minimumInvestment;
        uint256 maker;
    }

    modifier isOwner() {
        require(owners[msg.sender].id != 0);
        _;
    }

    modifier isAuditor() {
        require(auditors[msg.sender].id != 0);
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
    function addMaker(address newMakerAddress) public isOwner {
        makers[newMakerAddress] = Maker(makerIdsCounter);
        makerIdsCounter++;
    }

    /*
        REQUERIMIENTO PROPUESTAS 2, 4
    */
    function setStateClosed() public isOwner {
        if (systemState == SystemState.Proposal) {
            uint256 lastProposalId = proposalIdsCounter - 1;
            uint256 lastProposalId2 = lastProposalId - 1;
            if (lastProposalId > 0 && lastProposalId2 > 0) {
                Proposal memory proposal1 = proposals[lastProposalId];
                Proposal memory proposal2 = proposals[lastProposalId2];
                if (proposal1.isOpen && proposal2.isOpen) {
                    // 🤔 Hay q cerrar las dos propuestas??
                    systemState = SystemState.Closed;
                }
                else {
                    assert(false);
                }
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
    function setStateProposal() public isOwner {
        if (systemState == SystemState.Closed) {
            systemState = SystemState.Proposal;
        }
    }

    /*
        REQUERIMIENTO PROPUESTAS 7
    */
    function validateProposal(uint256 proposalId) public isAuditor {
        if (proposals[proposalId].id != 0) {    // Proposal existe
            proposals[proposalId].audited = true;
        }
    }

}
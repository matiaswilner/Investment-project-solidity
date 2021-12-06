//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "./Proposal.sol";

contract SmartInvestment {

    receive() external payable {}

    enum SystemState { Closed, Proposal, Voting }
    SystemState public systemState;

    event DeclareWinningProposalEvent(address proposalAddress, address maker, uint256 minimumInvestment);

    uint256 proposalIdsCounter = 1;
    uint256 makerIdsCounter = 1;
    uint256 auditorIdsCounter = 1;

    mapping(uint256 => address payable) public proposals;
    mapping(address => bool) public owners;
    mapping(address => Maker) public makers;
    mapping(address => bool) public auditors;

    address[] votingCloseAuthorizationAuditors;

    struct Maker {
        uint256 id;
        string name;
        string country;
        string passportNumber;
    }

    modifier isOwner() {
        require(owners[msg.sender] == true, "No es owner");
        _;
    }

    modifier isAuditor() {
        require(auditors[msg.sender] == true, "No es auditor");
        _;
    }

    modifier isMaker() {
        require(makers[msg.sender].id != 0, "No es maker");
        _;
    }

    modifier enableProposal() {
        require(makerIdsCounter >= 3, "No hay mas de 3 makers");
        require(auditorIdsCounter >= 2, "No hay mas de 2 auditors");
        _;
    }

    modifier proposalPeriod() {
        require(systemState == SystemState.Proposal, "No se encuentra en proposal period");
        _;
    }

    modifier votingPeriod() {
        require(systemState == SystemState.Voting, "No se encuentra en voting period");
        _;
    }

    constructor() {
        owners[msg.sender] = true;
        systemState = SystemState.Closed;
    }

    function isVoter(address voterAddress) external view returns(bool) {
        bool notOwner = owners[voterAddress] == false;
        bool notAuditor = auditors[voterAddress] == false;
        bool notMaker = makers[voterAddress].id == 0;
        return notOwner && notAuditor && notMaker;
    }

    function isVotingPeriod() external view returns(bool) {
        return systemState == SystemState.Voting;
    }

    function addOwner(address newOwnerAddress) external isOwner {
        owners[newOwnerAddress] = true;
    }

    function addMaker(address newMakerAddress, string calldata name, string calldata country, string calldata passportNumber) external isOwner {
        makers[newMakerAddress] = Maker(makerIdsCounter, name, country, passportNumber);
        makerIdsCounter++;
    }

    function addAuditor(address newAuditorAddress) external isOwner {
        auditors[newAuditorAddress] = true;
        auditorIdsCounter++;
    }

    function switchState() external isOwner {
        if (systemState == SystemState.Proposal) {
            setStateVoting();
        } else if (systemState == SystemState.Closed) {
            setStateProposal();
        } else if (systemState == SystemState.Voting) {
            setStateClosed();
        } else {
            revert();
        }
    }

    function setStateVoting() internal {
        require(proposalIdsCounter >= 2, "Se necesitan mas de 2 proposals");
        systemState = SystemState.Voting;
    }

    function setStateProposal() internal enableProposal {
        systemState = SystemState.Proposal;
    }

    function setStateClosed() internal {
        uint256 totalBalance = 0;
        for(uint256 i = 1; i < proposalIdsCounter && totalBalance <= 50 ether; i++) {
            totalBalance += address(proposals[i]).balance;
        }
        require(totalBalance >= 50 ether, "Se necesita que el total del balance de las propuestas sea mayor a 50");
        bool auditorsAuthorization = votingCloseAuthorizationAuditors[0] != address(0) && votingCloseAuthorizationAuditors[1] != address(0);
        require(auditorsAuthorization, "Se necesita autorizacion de auditores");
        systemState = SystemState.Closed;
        delete votingCloseAuthorizationAuditors[0];
        delete votingCloseAuthorizationAuditors[1];
        address proposalWinner = getProposalWinner();
        Proposal(proposalWinner).transferTenPercent();
        uint256 proposalWinnerId;
        for(uint256 i = 1; i < proposalIdsCounter; i++){
            if(proposals[i] != proposalWinner){
                Proposal(proposals[i]).transferTenPercent();
                Proposal(proposals[i]).transferFundsAndSelfDestroy(proposalWinner);
                delete proposals[i];
            }
            else {
                proposalWinnerId = i;
            }
        }
        Proposal proposalWinnerObject = Proposal(proposalWinner);
        emit DeclareWinningProposalEvent(proposalWinner, proposalWinnerObject._maker(), proposalWinnerObject._minimumInvestment());
        proposalWinnerObject.transferPropertyToMaker();
        delete proposals[proposalWinnerId];
        proposalIdsCounter = 1;
    }

    function validateProposal(uint256 proposalId) external isAuditor {
        if (proposals[proposalId] != address(0)) {
            Proposal(proposals[proposalId]).setAudited();
        }
    }

    function createProposal(string calldata name, string calldata description, uint256 minimumInvestment) external payable isMaker proposalPeriod {
        Proposal newProposal = new Proposal(proposalIdsCounter, false, false, name, description, minimumInvestment, msg.sender);
        address payable newProposalAddress = payable(address(newProposal));
        proposals[proposalIdsCounter] = newProposalAddress;
        proposalIdsCounter++;
    }

    function authorizeCloseVoting() external isAuditor {
        if (votingCloseAuthorizationAuditors.length == 0) {
            votingCloseAuthorizationAuditors.push(msg.sender);
        } else {
            if (votingCloseAuthorizationAuditors[0] != msg.sender) {
                votingCloseAuthorizationAuditors.push(msg.sender);
            } else {
                revert();
            }
        }
        
    }

    function getProposalWinner() internal view returns(address){
        address winner = proposals[1];
        for (uint256 i=2; i < proposalIdsCounter; i++) {
            if (proposals[i].balance > winner.balance) {
                winner = proposals[i];
            } else if (proposals[i].balance == winner.balance && Proposal(proposals[i])._votes() > Proposal(winner)._votes()) {
                winner = proposals[i];
            }
        }
        return winner;
    }

}
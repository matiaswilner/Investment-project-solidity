//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./Proposal.sol";

contract SmartInvestment {

    enum SystemState { Closed, Proposal, Voting }
    SystemState public systemState; // Estado actual del sistema

    uint256 proposalIdsCounter = 1;
    uint256 ownerIdsCounter = 1;
    uint256 makerIdsCounter = 1;
    uint256 auditorIdsCounter = 1;

    mapping(uint256 => address payable) public proposals;
    mapping(address => Owner) public owners;    // Si no usamos para nada el id, cambiar Owner por bool.
    mapping(address => Maker) public makers;
    mapping(address => Auditor) public auditors;    // Si no usamos para nada el id, cambiar Owner por bool.

    address[] votingCloseAuthorizationAuditors;

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

    
    modifier isVoter() {
        // Verificar que no esté en el mapping de Owners, Makers u Auditors (modificar⚠️⚠️⚠️⚠️⚠️⚠️)
        require(owners[msg.sender].id == 0);
        require(auditors[msg.sender].id == 0);
        require(makers[msg.sender].id == 0);
        _;
    }

    // HACER un isSmartInvestment modifier

    /*
        REQUERIMIENTO ROLES 8 Y 9
    */
    modifier enableProposal() {
        require(makerIdsCounter >= 3 && auditorIdsCounter >= 2);
        _;
    }

    modifier proposalPeriod() {
        require(systemState == SystemState.Proposal);
        _;
    }

    modifier votingPeriod() {
        require(systemState == SystemState.Voting);
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
    function addOwner(address newOwnerAddress) external isOwner {
        owners[newOwnerAddress] = Owner(ownerIdsCounter);
        ownerIdsCounter++;
    }

    /*
        REQUERIMIENTO ROLES 6
        Solo los owners podrán registrar makers, entonces
        debemos usar el modifier isOwner
    */
    // Al usar memory tiene costo extra, para ahorrar gas, puedo usar calldata (readonly, mas barato)
    function addMaker(address newMakerAddress, string calldata name, string calldata country, string calldata passportNumber) external isOwner {
        makers[newMakerAddress] = Maker(makerIdsCounter, name, country, passportNumber);
        makerIdsCounter++;
    }

    function switchState() external isOwner {
        if (systemState == SystemState.Proposal) {
            setStateVoting();
        } else if (systemState == SystemState.Closed) {
            setStateProposal();
        } else if (systemState == SystemState.Voting) {
            setStateClosed();
        } else {
            assert(false);  // Cuidado con el tema del gasto. assert(false) consume toodo el gas, PREFERIBLE USAR REVERT!!⚠️⚠️⚠️⚠️
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
        // Tenemos que ver como ajustar la logica porque hacemos delete de proposal
        uint256 totalBalance = 0;
        for(uint256 i = 1; i < proposalIdsCounter && totalBalance <= 50 ether; i++) {
            if(Proposal(proposals[i]).getIsOpen()){
                totalBalance += address(proposals[i]).balance;
            }
        }
        bool auditorsAuthorization = votingCloseAuthorizationAuditors[0] != address(0) && votingCloseAuthorizationAuditors[1] != address(0);
        if (totalBalance >= 50 ether && auditorsAuthorization) {
            systemState = SystemState.Closed;
            delete votingCloseAuthorizationAuditors[0];
            delete votingCloseAuthorizationAuditors[1];
            address proposalWinner = getProposalWinner();
            // QUEDAMOS ACÁ??? ⚠️❓❔❓❔🤔
        } else {
            assert(false);
        }
        
    }

    /*
        REQUERIMIENTO PROPUESTAS 7
    */
    function validateProposal(uint256 proposalId) external isAuditor {
        if (proposals[proposalId] != address(0)) {    // Proposal existe
            Proposal(proposals[proposalId]).setAudited();
        }
    }

    /*
        REQUERIMIENTO ROLES 7
    */
    function createProposal(string calldata name, string calldata description, uint256 minimumInvestment) external isMaker proposalPeriod {
        //proposals[proposalIdsCounter] = 
        Proposal newProposal = new Proposal(proposalIdsCounter, false, false, name, description, minimumInvestment, makers[msg.sender].id);
        address payable newProposalAddress = payable(address(newProposal));
        proposals[proposalIdsCounter] = newProposalAddress;
        proposalIdsCounter++;
    }

    function authorizeCloseVoting() external isAuditor {
        if (votingCloseAuthorizationAuditors[0] == address(0)) {
            votingCloseAuthorizationAuditors[0] = msg.sender;
        } else {
            if (votingCloseAuthorizationAuditors[0] != msg.sender) {
                votingCloseAuthorizationAuditors[1] = msg.sender;
            } else {
                assert(false);
            }
        }
        
    }

    function vote(uint256 proposalId) external payable isVoter votingPeriod {
        require(msg.value >= 5 ether);
        proposals[proposalId].transfer(msg.value);
        Proposal(proposals[proposalId]).addVote();
        // WARNING: validar que la proposalId existe ⚠️⚠️⚠️⚠️⚠️
    }

    // Documentar que lo resolvimos así y como lo resolvimos
    function getProposalWinner() internal view returns(address){
        address winner = proposals[1];
        for (uint256 i=2; i < proposalIdsCounter; i++) {
            if (proposals[i].balance > winner.balance) {
                winner = proposals[i];
            } else if (proposals[i].balance == winner.balance && Proposal(proposals[i]).getVotes() > Proposal(winner).getVotes()) {
                winner = proposals[i];
            }
        }
        return winner;
    }

}
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./Proposal.sol";

contract SmartInvestment {

    enum SystemState { Closed, Proposal, Voting }
    SystemState public systemState; // Estado actual del sistema

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
        require(owners[msg.sender] == true);
        _;
    }

    modifier isAuditor() {
        require(auditors[msg.sender] == true);
        _;
    }

    modifier isMaker() {
        require(makers[msg.sender].id != 0);
        _;
    }

    
    modifier isVoter() {
        // Verificar que no esté en el mapping de Owners, Makers u Auditors (modificar⚠️⚠️⚠️⚠️⚠️⚠️)
        require(owners[msg.sender] == false);
        require(auditors[msg.sender] == false);
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
        owners[msg.sender] = true;
        systemState = SystemState.Closed;
    }

    /*
        REQUERIMIENTO ROLES 5
        Solo un owner puede agregar otro owner, entonces
        debemos usar el modifier isOwner.
    */
    function addOwner(address newOwnerAddress) external isOwner {
        owners[newOwnerAddress] = true;
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
            revert();  // Cuidado con el tema del gasto. assert(false) consume toodo el gas, PREFERIBLE USAR REVERT!!⚠️⚠️⚠️⚠️
        }
    }

    /*
        REQUERIMIENTO PROPUESTAS 2, 4
    */
    function setStateVoting() internal {
        require(proposalIdsCounter > 1);
        systemState = SystemState.Voting;
        //makerIdsCounter = 1; - PREGUNTAR ESTO
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
            totalBalance += address(proposals[i]).balance;
        }
        bool auditorsAuthorization = votingCloseAuthorizationAuditors[0] != address(0) && votingCloseAuthorizationAuditors[1] != address(0);
        if (totalBalance >= 50 ether && auditorsAuthorization) {
            systemState = SystemState.Closed;
            delete votingCloseAuthorizationAuditors[0];
            delete votingCloseAuthorizationAuditors[1];
            address proposalWinner = getProposalWinner();
            for(uint256 i = 1; i < proposalIdsCounter; i++){
                Proposal(proposals[i]).transferTenPercent();
                if(proposals[i] != proposalWinner){
                    // OPCION 1
                    Proposal(proposals[i]).transferFunds(proposalWinner);
                    Proposal(proposals[i]).selfDestruct(proposalWinner);
                    // OPCION 2
                    Proposal(proposals[i]).transferFundsAndSelfDestroy(proposalWinner);
                }
            }
            Proposal proposalWinnerObject = Proposal(proposalWinner);
            emit DeclareWinningProposalEvent(proposalWinner, proposalWinnerObject._maker(), proposalWinnerObject._minimumInvestment());
            proposalWinnerObject.transferProperty(proposalWinnerObject._maker());
            proposalIdsCounter = 1;
            // Que onda esto? El ._maker ya es un address.. Hay que ponerle el payable en algun lado para transferir la propiedad del contrato?

            // QUEDAMOS ACÁ??? ⚠️❓❔❓❔🤔
            /*
                1 - Transferir 10% del balance de TODOS los contratos al contrato SmartInvestment. (comision)
                2 - Asignar la plata restante de los contratos perdedores al ganador.
                3 - Destruir los contratos perdedores. (Usar SELF DESTRUCT y ver como es (puede estar en las clases del 27/oct o 20/oct))
                4 - Asignar la propiedad del contrato ganador a su owner.

                El contrato ganador en el caso de que haya un empate de votos (por = cantidad de ethers), puede ser cualquiera de los dos.
            */
        } else {
            revert();
        }
        
    }

    /*
        REQUERIMIENTO PROPUESTAS 7
    */
    function validateProposal(uint256 proposalId) external isAuditor {
        if (proposals[proposalId] != address(0)) {    // Proposal existe
            // OPCION 1
            Proposal(proposals[proposalId]).setAudited();
            // OPCION 2 - En caso de borrar la funcion Proposal.setAudited()
            //Proposal(proposals[proposalId])._audited = true;
        }
    }

    /*
        REQUERIMIENTO ROLES 7
    */
    function createProposal(string calldata name, string calldata description, uint256 minimumInvestment) external isMaker proposalPeriod {
        //proposals[proposalIdsCounter] = 
        Proposal newProposal = new Proposal(proposalIdsCounter, false, false, name, description, minimumInvestment, msg.sender);
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
                revert();
            }
        }
        
    }

    /* 
        🧠🧠🧠🧠🧠🧠
        DOCUMENTAR que lo hicimos así para evitar llamar de un contrato al otro, ya que si
        estuviera esta func en Proposal deberiamos llamar aca para preguntar por el votingPeriod y
        si es o no voter el address, además de que un usuario tendría que llamr previamente a
        una func en SmartInvestment para saber el address de un contrato que no conoce (conocería sólo su Id)
    */
    function vote(uint256 proposalId) external payable isVoter votingPeriod {
        require(msg.value >= 5 ether);
        require(proposalId > 0 && proposalId < proposalIdsCounter);
        proposals[proposalId].transfer(msg.value);
        Proposal(proposals[proposalId]).addVote();
        // OPCION 2
        //Proposal(proposals[proposalId])._votes++;
        // WARNING: validar que la proposalId existe ⚠️⚠️⚠️⚠️⚠️ - HECHO
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
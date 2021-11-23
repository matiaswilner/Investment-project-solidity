//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./SmartInvestment.sol";

contract Proposal {

    // Ponerlas public, no hacer getters y setters
    address payable private _owner;

    uint256 public _id;
    bool public _isOpen;
    bool public _audited;
    string public _name;
    string public _description;
    uint256 public _minimumInvestment;
    address payable public _maker;
    uint256 public _votes;

    constructor(uint256 id, bool isOpen, bool audited, string memory name, string memory description, uint256 minimumInvestment, address maker){
        _owner = payable(msg.sender);
        _id = id;
        _isOpen = isOpen;
        _audited = audited;
        _name = name;
        _description = description;
        _minimumInvestment = minimumInvestment;
        _maker = payable(maker);
    }

    modifier isOwner() {
        require(_owner == msg.sender, "No es el owner");
        _;
    }

    function transferPropertyToMaker() external isOwner {
        _owner = _maker;
    }

    // OPCION 2  
    function transferFundsAndSelfDestroy(address destinationAddress) payable external isOwner {
        selfdestruct(payable(destinationAddress));
    }

    function transferTenPercent() external isOwner {
        uint256 tenPercent = (address(this).balance/10);
        bool transfered = payable(_owner).send(tenPercent);
        if (!transfered) {
            revert("No fueron transferidos!");
        }
    }

    /* 
        DEBE ESTAR SIII O SIII EN PROPOSAL y HACER TODDO ESO DE LA LLAMADA EN CONTRATO
        Desde la propuesta perguntar si esta abierto, sino hace revert, ademas de erificar que no sea un maker ni owner ni auditor.

        📃 Asumimos que siempre que se llama al vote el Owner va a ser el SmartInvestment
        📃 No verificamos que el proposalId exista porque si se llama al método Vote del contrato intel de esta address es xq existe la proposal.
    */
    function vote() external payable {
        require(msg.value >= 5 ether, "Necesita que sean mas de 5 ethers");
        require(_audited, "Proposal no esta auditada");
        require(SmartInvestment(_owner).isVotingPeriod(), "No es periodo de votacion");
        require(SmartInvestment(_owner).isVoter(msg.sender), "No es votante");
        _votes++;
    }

    function setAudited() external {
        _audited = true;
    }
}
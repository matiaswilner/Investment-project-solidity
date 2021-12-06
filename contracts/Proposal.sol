//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "./SmartInvestment.sol";

contract Proposal {

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

    function vote() external payable {
        require(msg.value >= 5 ether, "Necesita que sean mas de 5 ethers");
        require(_audited, "Proposal no esta auditada");
        require(SmartInvestment(_owner).isVotingPeriod(), "No es periodo de votacion");
        require(SmartInvestment(_owner).isVoter(msg.sender), "No es votante");
        _votes++;
    }

    function setAudited() external isOwner {
        _audited = true;
    }
}
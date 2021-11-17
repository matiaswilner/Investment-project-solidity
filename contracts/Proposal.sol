//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./Proposal.sol";

contract Proposal {

    // Ponerlas public, no hacer getters y setters
    address private _owner;

    uint256 public _id;
    bool public _isOpen;
    bool public _audited;
    string public _name;
    string public _description;
    uint256 public _minimumInvestment;
    address public _maker;
    uint256 public _votes;

    constructor(uint256 id, bool isOpen, bool audited, string memory name, string memory description, uint256 minimumInvestment, address maker){
        _owner = msg.sender;
        _id = id;
        _isOpen = isOpen;
        _audited = audited;
        _name = name;
        _description = description;
        _minimumInvestment = minimumInvestment;
        _maker = maker;
    }

    modifier isOwner() {
        require(_owner == msg.sender);
        _;
    }

    function transferPropertyToMaker() external isOwner {
        _owner = _maker;
    }

    // OPCION 2  
    function transferFundsAndSelfDestroy(address destinationAddress) external isOwner {
        selfdestruct(payable(destinationAddress));
    }

    function transferTenPercent() external isOwner {
        uint256 tenPercent = address(this).balance / 10;
        payable(_owner).transfer(tenPercent);
    }

    // BORRAR LOS GET

    function getIsOpen() external view returns(bool) {
        return _isOpen;
    }

    function getId() external view returns(uint256) {
        return _id;
    }

    function setAudited() external {
        _audited = true;
    }

    function addVote() external {
        _votes++;
    }

    function getVotes() external view returns(uint256) {
        return _votes;
    }
}
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./Proposal.sol";

contract Proposal {

    // Ponerlas public, no hacer getters y setters
    uint256 _id;
    bool _isOpen;
    bool _audited;
    string _name;
    string _description;
    uint256 _minimumInvestment;
    uint256 _maker;
    uint256 _votes;

    constructor(uint256 id, bool isOpen, bool audited, string memory name, string memory description, uint256 minimumInvestment, uint256 maker){
        _id = id;
        _isOpen = isOpen;
        _audited = audited;
        _name = name;
        _description = description;
        _minimumInvestment = minimumInvestment;
        _maker = maker;
    }

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
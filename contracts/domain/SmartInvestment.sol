//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract SmartInvestment {

    uint256 ownerIdsCounter = 1;
    uint256 makerIdsCounter = 1;
    uint256 auditorIdsCounter = 1;
    uint256 voterIdsCounter = 1;

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

    constructor() {
        owners[msg.sender] = Owner(ownerIdsCounter);
        ownerIdsCounter++;
    }

}
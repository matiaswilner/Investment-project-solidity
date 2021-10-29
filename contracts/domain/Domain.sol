//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

// PERSON

abstract contract Person {

    uint256 id;

}

contract Owner is Person {

}

contract Maker is Person {

    string name;
    string countryOfOrigin;
    string passportNumber;

}

contract Auditor is Person {

}

contract Voter is Person {

}

////

contract Proposal {

    uint id;
    string name;
    string description;
    /*⚠️FLOAT VALUE minimumInvestmentAmount;⚠️AGREGAR TIPO DE DATO NO SABEMOS AUN*/
    uint256 makerId;

}

contract Vote {

    uint id;
    uint voterId;
    uint proposalId;

}
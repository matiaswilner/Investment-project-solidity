const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

beforeEach(async function() {
  [owner, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
  const contractFactory = await ethers.getContractFactory("SmartInvestment");
  contractInstance = await contractFactory.deploy();
});

describe("========DEPLOY TEST======== Vote", async function() {
  it("SmartInvestment deployed", async function() {
    expect(contractInstance).to.be.ok;
  });
});

describe("Vote", async function() {
  it("should fail because there isn't 5 ethers or more", async function() { 
    await contractInstance.addMaker(addr1.address, "Maker 1", "UY", "24121321");
    await contractInstance.addMaker(addr2.address, "Maker 2", "UY", "532342");
    await contractInstance.addMaker(addr3.address, "Maker 3", "UY", "5423542");
    await contractInstance.addAuditor(addr4.address);
    await contractInstance.addAuditor(addr5.address);
    await contractInstance.switchState();
    await contractInstance.connect(addr1).createProposal("Proposal 1", "Description", 5);
  
    const proposalAddress = await contractInstance.proposals(1);

    const contractFactoryProp = await ethers.getContractFactory("Proposal");
    proposal = await contractFactoryProp.attach(proposalAddress);
    
    try {
      await proposal.connect(addr6).vote();
      expect.fail("Should have thrown exception 'No hay almenos 5 ethers enviados'");
    }
    catch (error) {
      expect(error.message).to.contain("Necesita que sean mas de 5 ethers");
    }
  });
  it("should fail without proposal being audited", async function() {
    await contractInstance.addMaker(addr1.address, "Maker 1", "UY", "24121321");
    await contractInstance.addMaker(addr2.address, "Maker 2", "UY", "532342");
    await contractInstance.addMaker(addr3.address, "Maker 3", "UY", "5423542");
    await contractInstance.addAuditor(addr4.address);
    await contractInstance.addAuditor(addr5.address);
    await contractInstance.switchState();
    await contractInstance.connect(addr1).createProposal("Proposal 1", "Description", 5);
  
    const proposalAddress = await contractInstance.proposals(1);

    const contractFactoryProp = await ethers.getContractFactory("Proposal");
    proposal = await contractFactoryProp.attach(proposalAddress);
        

    try {
      await proposal.connect(addr6).vote({ value : ethers.utils.parseEther("6") });
      expect.fail("Should have thrown exception 'Proposal no esta auditada'");
    }
    catch (error) {
      expect(error.message).to.contain("Proposal no esta auditada");
    }
  });
  it("should fail because it isn´t in voting period", async function() {
    await contractInstance.addMaker(addr1.address, "Maker 1", "UY", "24121321");
    await contractInstance.addMaker(addr2.address, "Maker 2", "UY", "532342");
    await contractInstance.addMaker(addr3.address, "Maker 3", "UY", "5423542");
    await contractInstance.addAuditor(addr4.address);
    await contractInstance.addAuditor(addr5.address);
    await contractInstance.switchState();
    await contractInstance.connect(addr1).createProposal("Proposal 1", "Description", 5);
  
    const proposalAddress = await contractInstance.proposals(1);

    contractInstance.connect(addr4).validateProposal(1);

    const contractFactoryProp = await ethers.getContractFactory("Proposal");
    proposal = await contractFactoryProp.attach(proposalAddress);
    


    try {
      await proposal.connect(addr6).vote({ value : ethers.utils.parseEther("6") });
      expect.fail("Should have thrown exception 'No es periodo de votacion'");
    }
    catch (error) {
      expect(error.message).to.contain("No es periodo de votacion");
    }
  });
  it("should fail because it isn´t a voter", async function() {
    await contractInstance.addMaker(addr1.address, "Maker 1", "UY", "24121321");
    await contractInstance.addMaker(addr2.address, "Maker 2", "UY", "532342");
    await contractInstance.addMaker(addr3.address, "Maker 3", "UY", "5423542");
    await contractInstance.addAuditor(addr4.address);
    await contractInstance.addAuditor(addr5.address);
    await contractInstance.switchState();
    await contractInstance.connect(addr1).createProposal("Proposal 1", "Description", 5);
    await contractInstance.connect(addr2).createProposal("Proposal 2", "Description", 4);
    await contractInstance.switchState();

    const proposalAddress = await contractInstance.proposals(1);

    contractInstance.connect(addr4).validateProposal(1);

    const contractFactoryProp = await ethers.getContractFactory("Proposal");
    proposal = await contractFactoryProp.attach(proposalAddress);
    


    try {
      await proposal.connect(addr2).vote({ value : ethers.utils.parseEther("6") });
      expect.fail("Should have thrown exception 'No es votante'");
    }
    catch (error) {
      expect(error.message).to.contain("No es votante");
    }
  });
  it("should succeed", async function() {
    await contractInstance.addMaker(addr1.address, "Maker 1", "UY", "24121321");
    await contractInstance.addMaker(addr2.address, "Maker 2", "UY", "532342");
    await contractInstance.addMaker(addr3.address, "Maker 3", "UY", "5423542");
    await contractInstance.addAuditor(addr4.address);
    await contractInstance.addAuditor(addr5.address);
    await contractInstance.switchState();
    await contractInstance.connect(addr1).createProposal("Proposal 1", "Description", 5);
    await contractInstance.connect(addr2).createProposal("Proposal 2", "Description", 4);
    await contractInstance.switchState();

    const proposalAddress = await contractInstance.proposals(1);

    contractInstance.connect(addr4).validateProposal(1);

    const contractFactoryProp = await ethers.getContractFactory("Proposal");
    proposal = await contractFactoryProp.attach(proposalAddress);

    await proposal.connect(addr6).vote({ value : ethers.utils.parseEther("6") });
    const val = await proposal._votes();
    expect(val.toString()).to.be.equal('1');  // 1 vote
  });
});


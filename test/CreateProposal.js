const { expect, should, assert } = require("chai");
const { ethers } = require("hardhat");

beforeEach(async function() {
  const contractFactory = await ethers.getContractFactory("SmartInvestment");
  contractInstance = await contractFactory.deploy();
});

describe("========DEPLOY TEST======== Create Proposal", async function() {
  it("SmartInvestment deployed", async function() {
    expect(contractInstance).to.be.ok;
  });
});

describe("Create proposal", async function() {
  // Tiene q ser maker, y estar en el proposal period
  it("Should fail because address is not maker", async function() {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    try {
        await contractInstance.createProposal("Proposal 1", "Description", 5);
        expect.fail("Should have thrown exception 'No es maker'");
    }
    catch (error) {
        expect(error.message).to.contain("No es maker");
    }
  });
  it("Should fail because proposal period not set", async function() {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    await contractInstance.addMaker(addr1.address, "Maker1", "UY", "356234623");
    try {
        await contractInstance.connect(addr1).createProposal("PN", "Desc", 352);
        expect.fail("Should have thrown exception 'No se encuentra en proposal period'");
    }
    catch (error) {
        expect(error.message).to.contain("No se encuentra en proposal period");
    }
  });
  it("Should succeed", async function() {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    await contractInstance.addMaker(addr1.address, "Maker1", "UY", "362346234");
    await contractInstance.addMaker(addr2.address, "Maker2", "AR", "462346234");
    await contractInstance.addMaker(addr3.address, "Maker3", "US", "463456345");
    await contractInstance.addAuditor(addr4.address);
    await contractInstance.addAuditor(addr5.address);
    await contractInstance.switchState();
    await contractInstance.connect(addr2).createProposal("P1", "P1 Desc", 35234);
    const propAddr = await contractInstance.proposals(1);
    const propCF = await ethers.getContractFactory("Proposal");
    const prop = await propCF.attach(propAddr);
    const propIdOK = await prop._id() == 1;
    const propIsOpenOK = await prop._isOpen() == false;
    const propIsAuditedOK = await prop._audited() == false;
    const propNameOK = await prop._name() == "P1";
    const propDescriptionOK = await prop._description() == "P1 Desc";
    const propMinimumInvestmentOK = await prop._minimumInvestment() == 35234;
    const propMakerOK = await prop._maker() == addr2.address;
    const propVotesOK = await prop._votes() == 0;
    assert.isTrue(
        propIdOK && propIsOpenOK && propIsAuditedOK &&
        propNameOK && propDescriptionOK && propMinimumInvestmentOK,
        propMakerOK && propVotesOK
    );
  });
});
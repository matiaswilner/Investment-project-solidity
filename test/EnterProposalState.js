const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

beforeEach(async function() {
  const contractFactory = await ethers.getContractFactory("SmartInvestment");
  contractInstance = await contractFactory.deploy();
});

describe("========DEPLOY TEST======== Proposal State", async function() {
  it("SmartInvestment deployed", async function() {
    expect(contractInstance).to.be.ok;
  });
});

describe("Switch to proposal state", async function() {
  it("should fail to switch without enough makers", async function() {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    await contractInstance.addAuditor(addr1.address);
    await contractInstance.addAuditor(addr2.address);
    try {
      await contractInstance.switchState();
      expect.fail("Should have thrown exception 'No hay mas de 3 makers'");
    }
    catch (error) {
      expect(error.message).to.contain("No hay mas de 3 makers");
    }
  });
  it("should fail without enough auditors", async function() {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    await contractInstance.addMaker(addr1.address, "Maker1", "UY", "385738964");
    await contractInstance.addMaker(addr2.address, "Maker2", "US", "4634632");
    await contractInstance.addMaker(addr3.address, "Maker3", "AR", "345734573");
    await contractInstance.addAuditor(addr4.address);
    try {
      await contractInstance.switchState();
      expect.fail("Should have thrown exception 'No hay mas de 2 auditors'");
    }
    catch (error) {
      expect(error.message).to.contain("No hay mas de 2 auditors");
    }
  });
  it("should succeed", async function() {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();
    await contractInstance.addMaker(addr1.address, "Maker1", "UY", "385738964");
    await contractInstance.addMaker(addr2.address, "Maker2", "US", "4634632");
    await contractInstance.addMaker(addr3.address, "Maker3", "AR", "345734573");
    await contractInstance.addAuditor(addr4.address);
    await contractInstance.addAuditor(addr5.address);
    await contractInstance.switchState();
    const val = await contractInstance.systemState();
    expect(val.toString()).to.be.equal('1');  // 1 = Proposal enum
  });
});


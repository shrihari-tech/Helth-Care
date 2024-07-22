const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HealthcareDataExchange", function () {
  let HealthcareDataExchange, healthcareDataExchange;
  let owner, patient1, patient2, viewer;

  beforeEach(async function () {
    [owner, patient1, patient2, viewer] = await ethers.getSigners();

    const HealthcareDataExchange = await ethers.getContractFactory("HealthcareDataExchange");
    healthcareDataExchange = await HealthcareDataExchange.deploy();
    //await healthcareDataExchange.deployed();
  });

  it("Should set the platform owner correctly", async function () {
    await healthcareDataExchange.setPlatformOwner(owner.address);
    expect(await healthcareDataExchange.platformOwner()).to.equal(owner.address);
  });

  it("Should not allow setting the platform owner twice", async function () {
    await healthcareDataExchange.setPlatformOwner(owner.address);
    await expect(healthcareDataExchange.setPlatformOwner(owner.address)).to.be.revertedWith("Platform owner already set");
  });

  it("Should register a new patient", async function () {
    await healthcareDataExchange.connect(patient1).registerPatient();
    const patientDetails = await healthcareDataExchange.getPatientDetails(1);
    expect(patientDetails[0]).to.equal(1);
    expect(patientDetails[1]).to.equal(patient1.address);
  });

  it("Should add health data for a patient", async function () {
    await healthcareDataExchange.connect(patient1).registerPatient();
    await healthcareDataExchange.connect(patient1).addHealthData(1, "hash1", "description1");
    const healthRecords = await healthcareDataExchange.viewHealthData(1);
    expect(healthRecords.length).to.equal(1);
    expect(healthRecords[0].dataHash).to.equal("hash1");
  });

  it("Should grant access to a viewer", async function () {
    await healthcareDataExchange.connect(patient1).registerPatient();
    await healthcareDataExchange.connect(patient1).grantAccess(1, viewer.address);
    const healthRecords = await healthcareDataExchange.connect(viewer).viewHealthData(1);
    expect(healthRecords.length).to.equal(0);
  });

  it("Should revoke access from a viewer", async function () {
    await healthcareDataExchange.connect(patient1).registerPatient();
    await healthcareDataExchange.connect(patient1).grantAccess(1, viewer.address);
    await healthcareDataExchange.connect(patient1).revokeAccess(1, viewer.address);
    await expect(healthcareDataExchange.connect(viewer).viewHealthData(1)).to.be.revertedWith("Not authorized to view health data.");
  });

  it("Should not allow unauthorized access to health data", async function () {
    await healthcareDataExchange.connect(patient1).registerPatient();
    await healthcareDataExchange.connect(patient1).addHealthData(1, "hash1", "description1");
    await expect(healthcareDataExchange.connect(viewer).viewHealthData(1)).to.be.revertedWith("Not authorized to view health data.");
  });

  it("Should prevent direct ETH transfers", async function () {
    await expect(
      patient1.sendTransaction({
        to: healthcareDataExchange.address,
        value: ethers.utils.parseEther("1"),
      })
    ).to.be.revertedWith("Direct ETH transfer not allowed");
  });
});

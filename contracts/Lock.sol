// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthcareDataExchange {
    // Structure to hold health data details
    struct HealthData {
        uint256 id;
        string dataHash;
        string description;
        uint256 timestamp;
    }

    // Structure to hold patient details
    struct Patient {
        uint256 id;
        address patientAddress;
        HealthData[] healthRecords;
        mapping(address => bool) authorizedViewers;
    }

    // Arrays to store patients
    Patient[] private patients;

    // Address of the platform owner
    address public platformOwner;

    // Modifier to restrict access to only the platform owner
    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can perform this action");
        _;
    }

    // Modifier to restrict access to only the patient
    modifier onlyPatient(uint256 _patientId) {
        require(msg.sender == patients[_patientId - 1].patientAddress, "Only patient can perform this action");
        _;
    }

    // Events to log actions
    event HealthDataAdded(uint256 patientId, uint256 dataId, string description);
    event AccessGranted(uint256 patientId, address viewer);
    event AccessRevoked(uint256 patientId, address viewer);

    // Function to set the platform owner (only callable once)
    function setPlatformOwner(address _platformOwner) public {
        require(platformOwner == address(0), "Platform owner already set");
        platformOwner = _platformOwner;
    }

    // Function to register a new patient
    function registerPatient() public {
        uint256 patientId = patients.length + 1;
        Patient storage newPatient = patients.push();
        newPatient.id = patientId;
        newPatient.patientAddress = msg.sender;
    }

    // Function to add health data for a patient
    function addHealthData(uint256 _patientId, string memory _dataHash, string memory _description) public onlyPatient(_patientId) {
        Patient storage patient = patients[_patientId - 1];
        uint256 dataId = patient.healthRecords.length + 1;
        HealthData memory newRecord = HealthData({
            id: dataId,
            dataHash: _dataHash,
            description: _description,
            timestamp: block.timestamp
        });
        patient.healthRecords.push(newRecord);
        emit HealthDataAdded(_patientId, dataId, _description);
    }

    // Function to grant access to a viewer
    function grantAccess(uint256 _patientId, address _viewer) public onlyPatient(_patientId) {
        Patient storage patient = patients[_patientId - 1];
        patient.authorizedViewers[_viewer] = true;
        emit AccessGranted(_patientId, _viewer);
    }

    // Function to revoke access from a viewer
    function revokeAccess(uint256 _patientId, address _viewer) public onlyPatient(_patientId) {
        Patient storage patient = patients[_patientId - 1];
        patient.authorizedViewers[_viewer] = false;
        emit AccessRevoked(_patientId, _viewer);
    }

    // Function to view health data (only for authorized viewers)
    function viewHealthData(uint256 _patientId) public view returns (HealthData[] memory) {
        Patient storage patient = patients[_patientId - 1];
        require(patient.authorizedViewers[msg.sender], "Not authorized to view health data.");
        return patient.healthRecords;
    }

    // Helper function to get basic patient details
    function getPatientDetails(uint256 _patientId) public view onlyPlatformOwner returns (uint256, address, uint256) {
        Patient storage patient = patients[_patientId - 1];
        return (patient.id, patient.patientAddress, patient.healthRecords.length);
    }

    // Fallback function to prevent accidental ETH transfer
    receive() external payable {
        revert("Direct ETH transfer not allowed");
    }
}

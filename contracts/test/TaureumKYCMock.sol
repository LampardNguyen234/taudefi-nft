//SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.4;

import "../lib/access/AccessControl.sol";

contract TaureumKYCMock is AccessControl {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    mapping(address => bytes32) private _userProofOfIdentity;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VERIFIER_ROLE, msg.sender);
    }

    function addVerifier(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!hasRole(VERIFIER_ROLE, addr), "ERR_ADDR_HAS_ROLE");
        grantRole(VERIFIER_ROLE, addr);
    }

    function removeVerifier(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(VERIFIER_ROLE, addr), "ERR_ADDR_NOT_HAS_ROLE");
        revokeRole(VERIFIER_ROLE, addr);
    }

    function isVerifiedUser(address addr) external view returns (bool){
        return hasRole(VERIFIER_ROLE, addr);
    }
}
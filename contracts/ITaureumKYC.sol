//SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.4;

interface ITaureumKYC {
    function isVerifiedUser(address addr) external view returns (bool);
}
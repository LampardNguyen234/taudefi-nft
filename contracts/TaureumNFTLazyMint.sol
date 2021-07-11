// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;
//
//import "./TaureumNFT.sol";
//import "./lib/access/AccessControl.sol";
//import "./lib/utils/cryptography/ECDSA.sol";
//
//contract TaureumNFTLazyMint is TaureumNFT, AccessControl {
//    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
//
//    constructor(address KYCAddress) TaureumNFT(KYCAddress)
//    {
//        _setupRole(MINTER_ROLE, _msgSender());
//    }
//
//    function redeem(address account, string calldata uri, uint8 license, uint expireDate, bytes calldata signature)
//    external
//    {
//        bytes memory data = abi.encodePacked(uri, license);
//        data = abi.encodePacked(data, expireDate);
//        require(_verify(_hash(account, data), signature), "Invalid signature");
//        mint(account, uri, license, expireDate);
//    }
//
//    function _hash(address account, bytes calldata data)
//    internal pure returns (bytes32)
//    {
//        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(data, account)));
//    }
//
//    function _verify(bytes32 digest, bytes memory signature)
//    internal view returns (bool)
//    {
//        return hasRole(MINTER_ROLE, ECDSA.recover(digest, signature));
//    }
//}

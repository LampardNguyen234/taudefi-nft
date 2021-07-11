// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./lib/token/ERC721/ERC721.sol";
import "./lib/access/AccessControl.sol";
import "./ITaureumKYC.sol";
import "./lib/utils/Counters.sol";

contract TaureumNFT is ERC721 {
    using Counters for Counters.Counter;
    /**
     * @dev A counter to track tokenId.
     */
    Counters.Counter private _tokenIds;

    /**
     * @dev The contract address for the KYC entry.
     */
    address _KYCAddress;

    /**
     * @dev Mapping from NFT ID to metadata uri.
     */
    mapping(uint256 => string) internal idToUri;

    /**
     * @dev Mapping from NFT ID to its first owner.
     */
    mapping(uint256 => address) internal idToFirstOwner;

    /**
     * @dev Mapping from NFT URI to its existence.
     */
    mapping(string => bool) internal uriExists;

    /**
     * @dev Mapping from NFT ID to the NFT property (encode the tokenData struct).
     *  - 1st byte determines the license type: 0 => personal license, 1 => full license).
     *  - Next 32 bytes determine the expiry date (expiry block number): MaxUint => no expiry date.
     *
     * TODO: consider adding the URI to this mapping.
     */
    mapping(uint256 => bytes) internal idToProperty;

    /**
   * @dev Guarantee that _to is able to receive more NFTs.
   * @param _to Owner address to validate.
   */
    modifier canReceiveNFT(
        address _to
    )
    {
        uint256 balance = balanceOf(_to);
        bool isVerifiedUser = ITaureumKYC(_KYCAddress).isVerifiedUser(_to);

        require(isVerifiedUser || balance < 10, "NFT_COUNT_MAX_EXCEEDED");
        _;
    }

    /**
     * @dev Guarantee the _uri does not exist.
     * @param _uri The IPFS URI of the NFT.
     */
    modifier notExists(
        string memory _uri
    )
    {
        require(!uriExists[_uri], "URI_EXISTS");
        _;
    }

    /**
     * @dev Guarantee the _tokenId is not expired and transferable.
     * @param _tokenId The NFT token ID to validate.
     */
    modifier transferable(
        uint256 _tokenId
    ) {
        require(_isTransferable(_tokenId), "TOKEN_NOT_TRANSFERABLE");
        _;
    }

    /**
     * @dev Emitted when `tokenId` token is minted for `to`.
     */
    event Mint(address indexed to, uint256 indexed tokenId, string uri, uint expiryDate);

    /**
     * @dev Create a new TaureumNFT contract and assign the KYCAddress to _KYCAddress.
     *
     * TODO: change the default name and symbol.
     */
    constructor(address KYCAddress) ERC721("Taureum NFT", "Taureum") {
        _KYCAddress = KYCAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
      * @dev Mint a new NFT.
      * It throws an exception if
      *    - uri does not exist.
      *    - to cannot receive NFTs.
      * @param to The address that will own the minted NFT.
      * @param uri The URI consists of metadata description of the minting NFT on the IPFS (without prefix).
      * @param license The license of the minting NFT (0 - personally-licensed or 1 - fully-licensed).
      * @param expiryDate The block number at which the minting NFT is expired.
      */
    function mint(
        address to,
        string calldata uri,
        uint8 license,
        uint expiryDate
    )
    public
    notExists(uri)
    canReceiveNFT(to)
    {
        require(license < 2, "LICENSE_MUST_BE_O_OR_1");
        require(expiryDate > block.number, "EXPIRY_DATE_NOT_VALID");
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        super._mint(to, id);
        _setTokenUri(id, uri);
        uriExists[uri] = true;
        idToFirstOwner[id] = to;
        idToProperty[id] = abi.encodePacked(license, expiryDate);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, idToUri[tokenId])) : idToUri[tokenId];
    }

    /**
     * @dev Return the properties of an NFT token.
     * @notice It throws if the tokenId does not exist.
     * @param _tokenId The NFT tokenID to check.
     */
    function getTokenData(uint256 _tokenId) public view returns(bytes memory tokenData) {
        tokenData = idToProperty[_tokenId];
        require(tokenData.length == 33, "TOKEN_NOT_EXIST");
        return tokenData;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @notice It throws an exception if
     *      - the tokenId is not transferable.
     *      - the receiver `to` cannot receive more TaureumNFTs.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override transferable(tokenId) canReceiveNFT(to) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @notice It throws an exception if
     *      - the tokenId is not transferable.
     *      - the receiver `to` cannot receive more TaureumNFTs.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override transferable(tokenId) canReceiveNFT(to) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Check if an NFT token is transferable.
     * @param _tokenId The NFT tokenID to check.
     */
    function _isTransferable(uint256 _tokenId) internal view returns (bool) {
        address firstOwner = idToFirstOwner[_tokenId];
        bytes memory tokenData = getTokenData(_tokenId);

        uint8 licenseType = uint8(tokenData[0]);
        if (licenseType != 1 && msg.sender != firstOwner) {
            return false;
        }

        uint expiryDate;
        assembly {
            tokenData := add(tokenData, 1)
            expiryDate := mload(add(tokenData, 0x20)) // tokenData[1:33]
        }
        return block.number < expiryDate;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    /**
     * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
     * @notice This is an internal function which should be called from user-implemented external
     * function.
     * @notice It throws an exception if the _tokenId does not exist.
     * @param _tokenId Id for which we want URI.
     * @param _uri String representing RFC 3986 URI.
     */
    function _setTokenUri(
        uint256 _tokenId,
        string calldata _uri
    )
    internal
    {
        require(_exists(_tokenId), "TOKEN_ID_NOT_EXISTED");
        idToUri[_tokenId] = _uri;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TauNFTBasic.sol";
import "./ERC721/ERC721Metadata.sol";
import "./utils/Counters.sol";

/**
 * @dev Implementation fo TauDefi NFT supporting metadata.
 */
contract TauNFTFull is
TauNFTBasic,
ERC721Metadata
{
    string constant URI_EXISTS = "004001";

    using Counters for Counters.Counter;
    /**
     * @dev A counter to track tokenId.
     */
    Counters.Counter private _tokenIds;

    /**
     * @dev A descriptive name for a collection of NFTs.
     */
    string internal nftName;

    /**
     * @dev An abbreviated name for NFTokens.
     */
    string internal nftSymbol;

    /**
     * @dev Mapping from NFT ID to metadata uri.
     */
    mapping(uint256 => string) internal idToUri;

    /**
     * @dev Mapping from NFT URI to its existence.
     */
    mapping(string => bool) internal uriExists;

    /**
     * @dev Guarantee the _uri does not exist.
     *
     * @param _uri The IPFS URI of the NFT.
     */
    modifier notExists(
        string memory _uri
    )
    {
        require(!uriExists[_uri], URI_EXISTS);
        _;
    }

    /**
     * @dev Contract constructor.
     * @notice When implementing this contract don't forget to set nftName and nftSymbol.
     */
    constructor(string memory _name, string memory _symbol) TauNFTBasic()
    {   
        // These settings are for testing purposes only.
        vipLevel[address(0x2bEa4c160c24702f2D12CD8F268540b063e048cA)] = 0;
        vipLevel[address(0x9246b568210bE024523AA00C8Beae58d0E9ebab3)] = 1;
        vipLevel[address(0x1a0E6Ff5FBb1536AfA64b07918fA7c837Af6282f)] = 2;
        
        nftName = _name;
        nftSymbol = _symbol;
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata interface
    }

    /**
     * @dev Returns a descriptive name for a collection of NFTokens.
     * @return _name Representing name.
     */
    function name()
    external
    override
    view
    returns (string memory _name)
    {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol()
    external
    override
    view
    returns (string memory _symbol)
    {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     *
     * @param _tokenId Id for which we want the URI.
     * @return URI of _tokenId.
     */
    function tokenURI(
        uint256 _tokenId
    )
    external
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
    {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, idToUri[_tokenId])) : idToUri[_tokenId];
    }

    /**
   * @dev Mint a new NFT.
   * It throws an exception if
   *    - _uri does not exist.
   *    - _to cannot receive NFTs.
   *
   * @param _to The address that will own the minted NFT.
   * @param _uri The URI consists of metadata description of the NFT on the IPFS (without prefix).
   */
    function mint(
        address _to,
        string memory _uri
    )
    public
    notExists(_uri)
    canReceiveNFT(_to)
    {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        super._mint(_to, id);
        _setTokenUri(id, _uri);
        uriExists[_uri] = true;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "ipfs://";
    }

    /**
     * @dev Burns a NFT.
     * @notice This is an internal function which should be called from user-implemented external
     * burn function. Its purpose is to show and properly initialize data structures when using this
     * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
     * NFT.
     * @param _tokenId ID of the NFT to be burned.
     */
    function _burn(
        uint256 _tokenId
    )
    internal
    override
    virtual
    {
        super._burn(_tokenId);
        string memory _uri = idToUri[_tokenId];
        delete idToUri[_tokenId];
        delete uriExists[_uri];
    }

    /**
     * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
     * @notice This is an internal function which should be called from user-implemented external
     * function. Its purpose is to show and properly initialize data structures when using this
     * implementation.
     *
     * @param _tokenId Id for which we want URI.
     * @param _uri String representing RFC 3986 URI.
     */
    function _setTokenUri(
        uint256 _tokenId,
        string memory _uri
    )
    internal
    validNFToken(_tokenId)
    {
        idToUri[_tokenId] = _uri;
    }

}
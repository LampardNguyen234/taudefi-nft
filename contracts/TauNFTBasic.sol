// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721/ERC721.sol";
import "./ERC721/ERC721TokenReceiver.sol";
import "./utils/AddressUtils.sol";
import "./utils/SupportInterface.sol";

/**
 * @dev Implementation of the TauDefi NFT.
 * This contract inherits from the ERC721 interface.
 */
contract TauNFTBasic is
  ERC721,
  SupportsInterface
{
  using AddressUtils for address;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant INVALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";
  string constant NFT_COUNT_MAX_EXCEEDED = "003009";

  /**
   * @dev This value is the hash of the function signature "onERC721Received(address,address,uint256,bytes)" indicating
   * that a contract can receive ERC721 tokens.
   * It equals to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

  /**
   * @dev Mapping from an address to its VIP level.
   * A VIP0 owner can own upto 50 NFTs (0).
   * A VIP1 owner can own upto 200 NFTs (1).
   * A VIP2 owner can own an unlimited number of NTFs (2).
   */
  mapping (address => uint8) internal vipLevel;

  /**
   * @dev Mapping from owner address to the number of their tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantee that the msg.sender is an owner or operator of the given NFT.
   *
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantee that the msg.sender is allowed to transfer NFT.
   *
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantee that _to is able to receive more NFTs.
   *
   * @param _to Owner address to Validate.
   */
  modifier canReceiveNFT(
    address _to
  )
  {
    /**
     * _to cannot be a zero address;
     */
    require (_to != address(0), ZERO_ADDRESS);

    /**
     * The vipLevel of _to allows its to receive more NFTs.
     */
    require(
      vipLevel[_to] == uint8(2)
      || vipLevel[_to] == uint8(1) && ownerToNFTokenCount[_to] < 200
      || vipLevel[_to] == uint8(0) && ownerToNFTokenCount[_to] < 50,
      NFT_COUNT_MAX_EXCEEDED
    );
    _;
  }

  /**
   * @dev Guarantee that _tokenId is a valid Token.
   *
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), INVALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  /**
   * @dev Safely transfer the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice It throws an exception if
   *    - `msg.sender` is not the current owner, or not an authorized operator, or not the approved address for this NFT.
   *    - `_from` is not the current owner.
   *    - `_to` cannot receive NFTs.
   *    - `_tokenId` is not a valid NFT.
   * When transfer is complete, this function also checks if `_to` is a smart contract (code size > 0).
   * If so, it calls `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   *
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @dev Safely transfer the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other above function with an extra data parameter, except this function
   * just sets data to "".
   *
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Transfer the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice It throws an exception if
   *    - `msg.sender` is not the current owner, or not an authorized operator, or not the approved address for this NFT.
   *    - `_from` is not the current owner.
   *    - `_tokenId` is not a valid NFT.
   * @notice The caller is responsible for confirming that `_to` is capable of receiving NFTs or else
   * they may be permanently lost. We encourage users to use `safeTransferFrom` if possible.
   *
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);

    _transfer(_to, _tokenId);
  }

  /**
   * @dev Set or re-affirm the approved address for an NFT. This function can be changed to payable.
   * @notice The zero address indicates there is no approved address.
   * It throws an exception if
   *    - `msg.sender` is not the current NFT owner, or not an authorized operator of the current owner.
   *    - `_approved address is the owner of `_tokenId`.
   *
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   *
   * It emits an {Approval} event.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enable or disable approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets.
   * @notice It does not perform any check and works even if sender doesn't own any tokens at the time.
   * It throws an exception if `msg.Sender` = `_operator`.
   *
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   *
   * It emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    require(msg.sender != _operator, IS_OWNER);
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev Return the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   *
   * @param _owner Address for whom to query the balance.
   *
   * @return The number of NFTs the _owner owns.
   */
  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   *
   * @param _tokenId The identifier for an NFT.
   *
   * @return _owner The owner address of _tokenId.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), INVALID_NFT);
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice It throws an exception if
   *    - `_tokenId` is not a valid NFT.
   *
   * @param _tokenId ID of the NFT to query the approval of.
   *
   * @return The address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for all NFTs of the `_owner`.
   *
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   *
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  /**
   * @dev Actually perform the transfer.
   * @notice This function does NO check. The caller must make sure msg.Sender can transfer _tokenId,
   * and _to can receive _tokenId.
   *
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   *
   * It emits a {Transfer} event.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   *
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   *
   * It emits a {Transfer} event.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   *
   * @param _tokenId ID of the NFT to be burned.
   *
   * It emits a {Transfer} event.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  /**
   * @dev Removes a NFT from owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   *
   * @param _from Address from which we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  /**
   * @dev Assign a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   *
   * @param _to Address to which we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
    canReceiveNFT(_to)
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }

  /**
   * @dev Helper function that gets the number of NFTs of owner.
   *
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   *
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
    canReceiveNFT(_to)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retVal = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retVal == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  /**
   * @dev Clear the current approval of a given NFT ID.
   *
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    delete idToApproval[_tokenId];
  }

}
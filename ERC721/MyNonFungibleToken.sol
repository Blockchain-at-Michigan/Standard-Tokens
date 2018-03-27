pragma solidity ^0.4.18;

import "./ERC721Basic.sol";
import "./ERC721Receiver.sol";
import "./SafeMath.sol";
import "./AddressUtils.sol";
import "./owned.sol";

contract HeroToken is ERC721Basic, Owned {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant HERO_TOKEN_RECEIVED = 0xf0b9e5ba;

  struct Hero {
      string name;
      string symbol;
      uint Id;
  }

  mapping (uint256 => Hero) public indexToHero;

  uint public totalHeroes;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal heroTokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal heroTokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedHeroTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param heroTokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 heroTokenId) {
    require(ownerOf(heroTokenId) == msg.sender);
    _;
  }

  /**
  * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
  * @param heroTokenId uint256 ID of the token to validate
  */
  modifier canTransfer(uint256 heroTokenId) {
    require(isApprovedOrOwner(msg.sender, heroTokenId));
    _;
  }

  function createHero(address _to, string name, string symbol) public onlyOwner {
    require(_to != address(0));
    _mint(_to, name, symbol);
  }


  /**
  * @dev Gets the balance of the specified address
  * @param heroOwner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address heroOwner) public view returns (uint256) {
    require(heroOwner != address(0));
    return ownedHeroTokensCount[heroOwner];
  }

  /**
  * @dev Gets the owner of the specified token ID
  * @param heroTokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 heroTokenId) public view returns (address) {
    address owner = heroTokenOwner[heroTokenId];
    require(owner != address(0));
    return owner;
  }

  /**
  * @dev Returns whether the specified token exists
  * @param heroTokenId uint256 ID of the token to query the existance of
  * @return whether the token exists
  */
  function exists(uint256 heroTokenId) public view returns (bool) {
    address owner = heroTokenOwner[heroTokenId];
    return owner != address(0);
  }

  /**
  * @dev Approves another address to transfer the given token ID
  * @dev The zero address indicates there is no approved address.
  * @dev There can only be one approved address per token at a given time.
  * @dev Can only be called by the token owner or an approved operator.
  * @param _to address to be approved for the given token ID
  * @param heroTokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 heroTokenId) public {
    address owner = ownerOf(heroTokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(heroTokenId) != address(0) || _to != address(0)) {
      heroTokenApprovals[heroTokenId] = _to;
      emit Approval(owner, _to, heroTokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param heroTokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
   */
  function getApproved(uint256 heroTokenId) public view returns (address) {
    return heroTokenApprovals[heroTokenId];
  }


  /**
  * @dev Sets or unsets the approval of a given operator
  * @dev An operator is allowed to transfer all tokens of the sender on their behalf
  * @param _to operator address to set the approval
  * @param _approved representing the status of the approval to be set
  */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  /**
  * @dev Transfers the ownership of a given token ID to another address
  * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
  * @dev Requires the msg sender to be the owner, approved, or operator
  * @param _from current owner of the token
  * @param _to address to receive the ownership of the given token ID
  * @param heroTokenId uint256 ID of the token to be transferred
  */
  function transferFrom(address _from, address _to, uint256 heroTokenId) public canTransfer(heroTokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, heroTokenId);
    removeTokenFrom(_from, heroTokenId);
    addTokenTo(_to, heroTokenId);

    emit Transfer(_from, _to, heroTokenId);
  }

  /**
  * @dev Safely transfers the ownership of a given token ID to another address
  * @dev If the target address is a contract, it must implement `onERC721Received`,
  *  which is called upon a safe transfer, and return the magic value
  *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
  *  the transfer is reverted.
  * @dev Requires the msg sender to be the owner, approved, or operator
  * @param _from current owner of the token
  * @param _to address to receive the ownership of the given token ID
  * @param heroTokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(address _from, address _to, uint256 heroTokenId) public canTransfer(heroTokenId) {
    safeTransferFrom(_from, _to, heroTokenId, "");
  }

  /**
  * @dev Safely transfers the ownership of a given token ID to another address
  * @dev If the target address is a contract, it must implement `onERC721Received`,
  *  which is called upon a safe transfer, and return the magic value
  *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
  *  the transfer is reverted.
  * @dev Requires the msg sender to be the owner, approved, or operator
  * @param _from current owner of the token
  * @param _to address to receive the ownership of the given token ID
  * @param heroTokenId uint256 ID of the token to be transferred
  * @param _data bytes data to send along with a safe transfer check
  */
  function safeTransferFrom(address _from, address _to, uint256 heroTokenId, bytes _data) public canTransfer(heroTokenId) {
    transferFrom(_from, _to, heroTokenId);
    require(checkAndCallSafeTransfer(_from, _to, heroTokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param heroTokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address _spender, uint256 heroTokenId) internal view returns (bool) {
    address owner = ownerOf(heroTokenId);
    return _spender == owner || getApproved(heroTokenId) == _spender || isApprovedForAll(owner, _spender);
  }

  /**
  * @dev Internal function to mint a new token
  * @dev Reverts if the given token ID already exists
  * @param _to The address that will own the minted token
  */
  function _mint(address _to, string name, string symbol) internal {
    require(_to != address(0));
    uint heroIndex = totalHeroes;
    indexToHero[totalHeroes] = Hero(name, symbol, uint(keccak256(name)));
    totalHeroes = totalHeroes.add(1);
    addTokenTo(_to, heroIndex);
    emit Transfer(address(0), _to, heroIndex);
  }

  /**
  * @dev Internal function to burn a specific token
  * @dev Reverts if the token does not exist
  * @param heroTokenId uint256 ID of the token being burned by the msg.sender
  */
  function _burn(address _owner, uint256 heroTokenId) internal {
    clearApproval(_owner, heroTokenId);
    removeTokenFrom(_owner, heroTokenId);
    emit Transfer(_owner, address(0), heroTokenId);
  }

  /**
  * @dev Internal function to clear current approval of a given token ID
  * @dev Reverts if the given address is not indeed the owner of the token
  * @param _owner owner of the token
  * @param heroTokenId uint256 ID of the token to be transferred
  */
  function clearApproval(address _owner, uint256 heroTokenId) internal {
    require(ownerOf(heroTokenId) == _owner);
    if (heroTokenApprovals[heroTokenId] != address(0)) {
      heroTokenApprovals[heroTokenId] = address(0);
      emit Approval(_owner, address(0), heroTokenId);
    }
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param heroTokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addTokenTo(address _to, uint256 heroTokenId) internal {
    require(heroTokenOwner[heroTokenId] == address(0));
    heroTokenOwner[heroTokenId] = _to;
    ownedHeroTokensCount[_to] = ownedHeroTokensCount[_to].add(1);
  }

  /**
  * @dev Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param heroTokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function removeTokenFrom(address _from, uint256 heroTokenId) internal {
    require(ownerOf(heroTokenId) == _from);
    ownedHeroTokensCount[_from] = ownedHeroTokensCount[_from].sub(1);
    heroTokenOwner[heroTokenId] = address(0);
  }

  /**
  * @dev Internal function to invoke `onERC721Received` on a target address
  * @dev The call is not executed if the target address is not a contract
  * @param _from address representing the previous owner of the given token ID
  * @param _to target address that will receive the tokens
  * @param heroTokenId uint256 ID of the token to be transferred
  * @param _data bytes optional data to send along with the call
  * @return whether the call correctly returned the expected magic value
  */
  function checkAndCallSafeTransfer(address _from, address _to, uint256 heroTokenId, bytes _data) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, heroTokenId, _data);
    return (retval == HERO_TOKEN_RECEIVED);
  }
}
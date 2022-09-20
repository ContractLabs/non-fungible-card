// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NFCUpgradeable.sol";

import "./internal-upgradeable/RentableNFTUpgradeable.sol";

import "./interfaces-upgradeable/IRentableNFCUpgradeable.sol";

contract RentableNFCUpgradeable is
    NFCUpgradeable,
    RentableNFTUpgradeable,
    IRentableNFCUpgradeable
{
    using SafeCastUpgradeable for uint256;

    uint256 public limit;

    function init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        uint256 limit_
    ) external initializer {
        __NFC_init(
            name_,
            symbol_,
            baseURI_,
            18,
            ///@dev value is equal to keccak256("RentableNFCUpgradeable")
            0x8f0d2d8abbd7c54281bae66528ef94d45e2883ff8bcc0f44d38a570078d4694d
        );

        _setLimit(limit_);
    }

    function deposit(
        uint256 tokenId_,
        uint256 deadline_,
        bytes calldata signature_
    ) external payable override nonReentrant whenNotPaused {
        address sender = _msgSender();
        _checkLock(sender);
        _deposit(sender, tokenId_, deadline_, signature_);

        _setUser(tokenId_, sender);
    }

    function setLimit(uint256 limit_)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        emit LimitSet(limit, limit_);
        _setLimit(limit_);
    }

    function setUser(uint256 tokenId, address user)
        external
        override
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        _checkLock(user);
        _setUser(tokenId, user);
    }

    function userOf(uint256 tokenId)
        external
        view
        override
        returns (address user)
    {
        user = _users[tokenId].user;
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(NFCUpgradeable, RentableNFTUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    function _setUser(uint256 tokenId_, address user_) internal {
        UserInfo memory userInfo = _users[tokenId_];
        if (userInfo.expires++ > limit) revert RentableNFC__LimitExceeded();
        unchecked {
            emit UserUpdated(tokenId_, userInfo.user = user_, userInfo.expires);
        }

        _users[tokenId_] = userInfo;
    }

    function _setLimit(uint256 limit_) internal {
        limit = limit_;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    )
        internal
        override(
            ERC721PresetMinterPauserAutoIdUpgradeable,
            RentableNFTUpgradeable
        )
    {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

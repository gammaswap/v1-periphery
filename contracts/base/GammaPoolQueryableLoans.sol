// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "../interfaces/ILoanStore.sol";
import "./GammaPoolERC721.sol";

/// @title GammaPoolQueryableLoans
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Makes ERC721 loans queryable by PositionManager
abstract contract GammaPoolQueryableLoans is GammaPoolERC721 {

    /// @dev Database where it will store loan information. dataStore has to know this address though to accept messages
    address public dataStore;

    /// @dev Initializes the contract by setting `dataStore`.
    constructor(address _dataStore) {
        dataStore = _dataStore;
    }

    /// @dev Mint tokenId of loan as ERC721 NFT and store in mappings so that it can be queried
    /// @param pool - pool loan identified by `tokenId` belongs to
    /// @param tokenId - unique identifier of loan
    /// @param owner - owner of loan
    function mintQueryableLoan(address pool, uint256 tokenId, address owner) internal virtual {
        _safeMint(owner, tokenId);
        if(dataStore != address(0)) {
            ILoanStore(dataStore).addLoanToOwner(pool, tokenId, owner);
        }
    }

    /// @dev See {GammaPoolERC721-_transfer}.
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);
        if(dataStore != address(0)) {
            ILoanStore(dataStore).transferLoan(from, to, tokenId);
        }
    }
}

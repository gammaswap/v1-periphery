// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./GammaPoolERC721.sol";

/// @title GammaPoolQueryableLoans
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Makes ERC721 loans queryable by PositionManager
abstract contract GammaPoolQueryableLoans is GammaPoolERC721 {

    /// @dev Struct to store identifiable information about loan to perform queries in PositionManager
    struct LoanInfo {
        /// @dev Address of pool loan belongs to
        address pool;
        /// @dev Add loan to mappings by user
        uint256 byOwnerAndPoolIdx;
        /// @dev Add loan to mappings by user
        uint256 byOwnerIdx;
    }

    mapping(uint256 => LoanInfo) internal loanToInfo;
    mapping(address => uint256[]) internal loansByOwner;
    mapping(address => mapping(address => uint256[])) internal loansByOwnerAndPool;

    /// @dev Add loan to mappings by user so that they can be queried
    /// @param pool - pool loan identified by `tokenId` belongs to
    /// @param tokenId - unique identifier of loan
    /// @param owner - owner of loan
    function addLoanToOwner(address pool, uint256 tokenId, address owner) internal virtual {
        uint256 byOwnerIdx = loansByOwner[owner].length;
        uint256 byOwnerAndPoolIdx = loansByOwnerAndPool[owner][pool].length;
        loanToInfo[tokenId] = LoanInfo({ pool: pool, byOwnerIdx: byOwnerIdx, byOwnerAndPoolIdx: byOwnerAndPoolIdx });
        loansByOwnerAndPool[owner][pool].push(tokenId);
        loansByOwner[owner].push(tokenId);
    }

    /// @dev Mint tokenId of loan as ERC721 NFT and store in mappings so that it can be queried
    /// @param pool - pool loan identified by `tokenId` belongs to
    /// @param tokenId - unique identifier of loan
    /// @param owner - owner of loan
    function mintQueryableLoan(address pool, uint256 tokenId, address owner) internal virtual {
        _safeMint(owner, tokenId);
        addLoanToOwner(pool, tokenId, owner);
    }

    /// @dev See {GammaPoolERC721-_transfer}.
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);
        LoanInfo memory _loanInfo = loanToInfo[tokenId];

        loansByOwnerAndPool[from][_loanInfo.pool][_loanInfo.byOwnerAndPoolIdx] = 0;
        loansByOwner[from][_loanInfo.byOwnerIdx] = 0;

        addLoanToOwner(_loanInfo.pool, tokenId, to);
    }
}

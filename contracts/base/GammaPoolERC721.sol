pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GammaPoolERC721 is ERC721 {

    error ERC721Forbidden();
    error ERC721ApproveOwner();

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function isForbidden(uint256 tokenId) internal virtual view {
        if(!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert ERC721Forbidden();
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        isForbidden(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        isForbidden(tokenId);

        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);

        if(to == owner) {
            revert ERC721ApproveOwner();
        }

        if(_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ERC721Forbidden();
        }

        _approve(to, tokenId);
    }

}

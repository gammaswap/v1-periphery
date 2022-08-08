// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import '../PositionManager.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract TestPositionManager is PositionManager {
    
    constructor(address _factory, address _WETH, bytes32 _initCodeHash) PositionManager( _factory,  _WETH, _initCodeHash) {
    }

    function createTestLoan(address to) external virtual returns(uint256 tokenId) {
        tokenId = 1;
        _safeMint(to, tokenId);
    }
}
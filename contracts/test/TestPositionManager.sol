// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "../PositionManager.sol";

contract TestPositionManager is PositionManager {

    constructor(address _factory, address _WETH) PositionManager( _factory,  _WETH) {
    }

    function createTestLoan(address to) external virtual returns(uint256 tokenId) {
        tokenId = 1;
        _safeMint(to, tokenId);
    }
}
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../PositionManager.sol";

contract TestPositionManager is PositionManager {

    bytes32 immutable public initCodeHash;

    constructor(address _factory, address _WETH, bytes32 _initCodeHash) PositionManager( _factory,  _WETH) {
        initCodeHash = _initCodeHash;
    }

    function getGammaPoolAddress(address cfmm, uint24 protocol) internal override virtual view returns(address) {
        return AddressCalculator.calcAddress(factory, AddressCalculator.getGammaPoolKey(cfmm, protocol), initCodeHash);
    }

    function createTestLoan(address to) external virtual returns(uint256 tokenId) {
        tokenId = 1;
        _safeMint(to, tokenId);
    }
}
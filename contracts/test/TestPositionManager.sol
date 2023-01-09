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

    function testCheckMinReserves(uint256[] calldata amounts, uint256[] calldata amountsMin) external virtual pure {
        checkMinReserves(amounts, amountsMin);
    }

    function testCheckMinCollateral(uint128[] memory amounts, uint128[] memory amountsMin) external virtual pure {
        checkMinCollateral(amounts, amountsMin);
    }

    function tokenURI(uint256) public view virtual override returns (string memory) {
        return "";
    }

}



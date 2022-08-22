// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "../interfaces/external/IERC165.sol";

abstract contract GammaPoolERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

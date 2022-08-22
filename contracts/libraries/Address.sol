// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.1;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

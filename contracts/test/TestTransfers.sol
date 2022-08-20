// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../base/Transfers.sol";
import "../interfaces/ITransfers.sol";

contract TestTransfers is Transfers {
    constructor(address _WETH) Transfers(_WETH) {
    }

    function testSend(address token, address sender, address to, uint256 amount) external {
        send(token, sender, to, amount);
    }
}
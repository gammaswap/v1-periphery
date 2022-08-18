// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../base/Transfers.sol";
import "../interfaces/ITransfers.sol";
import 'hardhat/console.sol';

contract TestTransfers is Transfers {
    constructor(address _WETH) Transfers(_WETH) {
    }

    receive() external payable override {
    }

    function testUnwrapWETH(uint256 minAmt, address to) external payable virtual {
        unwrapWETH(minAmt, to);
    }

    function testRefundETH() external payable virtual {
        refundETH();
    }

    function testClearToken(address token, uint256 minAmt, address to) external payable virtual {
        clearToken(token, minAmt, to);
    }

    function testSend(address token, address sender, address to, uint256 amount) external virtual {
        send(token, sender, to, amount);
    }
}
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

interface ISendTokensCallback {

    struct SendTokensCallbackData {
        address payer;
        address cfmm;
        uint16 protocolId;
    }

    function sendTokensCallback(address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external;
}

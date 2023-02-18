// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../base/Transfers.sol";
import "../interfaces/ITransfers.sol";

contract TestTransfers is Transfers {
    constructor(address _WETH) Transfers(_WETH) {
    }


    function getGammaPoolAddress(address cfmm, uint16) internal virtual override view returns(address) {
        return cfmm;
    }

    function testUnwrapWETH() public payable {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));

        if (wethBal > 0) {
            IWETH(WETH).withdraw(wethBal);
        }
    }

    function testSend(address token, address sender, address to, uint256 amount) external {
        send(token, sender, to, amount);
    }
}
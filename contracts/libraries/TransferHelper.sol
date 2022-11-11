// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {

    error STF_Fail();
    error ST_Fail();
    error SA_Fail();
    error STE_Fail();

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
        address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert STF_Fail();
        }
    }

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert ST_Fail();
        }
    }

    function safeApprove(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.approve.selector, to, value));
        if(!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert SA_Fail();
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if(!success) {
            revert STE_Fail();
        }
    }
}
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPoolExternal.sol";
import "./TestGammaPool2.sol";

contract TestGammaPoolExternal is TestGammaPool2, IGammaPoolExternal {

    struct params {
        uint256 num1;
        address to;
    }

    address immutable public override externalRebalanceStrategy;
    address immutable public override externalLiquidationStrategy;

    constructor(uint16 protocolId_, address factory_,  address borrowStrategy_, address repayStrategy_, address rebalanceStrategy_,
        address shortStrategy_, address singleLiquidationStrategy_, address batchLiquidationStrategy_, address viewer_,
        address externalRebalanceStrategy_, address externalLiquidationStrategy_) TestGammaPool2(protocolId_, factory_,
        borrowStrategy_, repayStrategy_, rebalanceStrategy_, shortStrategy_, singleLiquidationStrategy_, batchLiquidationStrategy_,
        viewer_) {
        externalRebalanceStrategy = externalRebalanceStrategy_;
        externalLiquidationStrategy = externalLiquidationStrategy_;
    }

    function rebalanceExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external virtual override returns(uint256 loanLiquidity, uint128[] memory tokensHeld) {
        params memory _params = abi.decode(data, (params));
        tokensHeld = new uint128[](2);
        tokensHeld[0] = uint128(amounts[0] + 10);
        tokensHeld[1] = uint128(amounts[1] + 20);
        loanLiquidity = uint256(uint160(_params.to)) + _params.num1 + lpTokens;
    }

    function liquidateExternally(uint256 tokenId, uint128[] calldata amounts, uint256 lpTokens, address to, bytes calldata data) external virtual override returns(uint256 loanLiquidity, uint256[] memory refund) {
        refund = new uint256[](2);
        refund[0] = uint256(amounts[0]) + 30;
        refund[1] = uint256(amounts[1]) + 40;
        return(lpTokens, refund);
    }
}

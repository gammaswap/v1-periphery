// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./TestGammaPool.sol";

contract TestGammaPool2 is TestGammaPool{
    constructor(uint16 _protocolId, address _factory, address _longStrategy, address _shortStrategy, address _liquidationStrategy)
        TestGammaPool(_protocolId, _factory, _longStrategy, _shortStrategy, _liquidationStrategy) {

    }

    function loan(uint256) external virtual override view returns(IGammaPool.LoanData memory _loanData) {
        _loanData.id = 20;
        _loanData.poolId = cfmm;
        _loanData.tokensHeld = new uint128[](2);
        _loanData.tokensHeld[1] = 1;
        _loanData.liquidity = 21;
        _loanData.lpTokens = 22;
        _loanData.rateIndex = 23;
        _loanData.initLiquidity = 24;
        _loanData.tokenId = 25;
    }/**/
}

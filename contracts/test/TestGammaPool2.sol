// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "./TestGammaPool.sol";

contract TestGammaPool2 is TestGammaPool{

    uint256 public utilRate;
    uint256 public borrowRate;
    uint256 public accFeeIndex;
    uint256 public lastPrice;

    constructor(uint16 protocolId_, address factory_,  address borrowStrategy_, address repayStrategy_, address rebalanceStrategy_,
        address shortStrategy_, address singleLiquidationStrategy_, address batchLiquidationStrategy_, address viewer_)
        TestGammaPool(protocolId_, factory_, borrowStrategy_, repayStrategy_, rebalanceStrategy_, shortStrategy_,
            singleLiquidationStrategy_, batchLiquidationStrategy_, viewer_) {
    }

    function loan(uint256) public virtual override view returns(LoanData memory _loanData) {
        _loanData.id = 20;
        _loanData.poolId = cfmm;
        _loanData.tokensHeld = new uint128[](2);
        _loanData.tokensHeld[1] = 1;
        _loanData.liquidity = 21;
        _loanData.lpTokens = 22;
        _loanData.rateIndex = 23;
        _loanData.initLiquidity = 24;
        _loanData.tokenId = 25;
    }

    function setLatestRates(uint256 _utilRate, uint256 _borrowRate, uint256 _accFeeIndex, uint256 _lastPrice) external virtual {
        utilRate = _utilRate;
        borrowRate = _borrowRate;
        accFeeIndex = _accFeeIndex;
        lastPrice = _lastPrice;
    }

    function getLatestRates() external virtual override view returns(RateData memory data) {
        data.utilizationRate = utilRate;
        data.borrowRate = borrowRate;
        data.accFeeIndex = accFeeIndex;
        data.currBlockNumber = block.number;
        data.lastPrice = lastPrice;
    }
}

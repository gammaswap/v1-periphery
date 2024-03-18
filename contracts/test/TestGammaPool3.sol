// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./TestGammaPool2.sol";

contract TestGammaPool3 is TestGammaPool2 {

    constructor(uint16 protocolId_, address factory_,  address borrowStrategy_, address repayStrategy_, address rebalanceStrategy_,
        address shortStrategy_, address singleLiquidationStrategy_, address batchLiquidationStrategy_, address viewer_)
        TestGammaPool2(protocolId_, factory_, borrowStrategy_, repayStrategy_, rebalanceStrategy_, shortStrategy_,
        singleLiquidationStrategy_, batchLiquidationStrategy_, viewer_) {
    }

    function mintTo(address user, uint256 amount) external {
        _mint(user, amount);
    }

    function initialize(address _cfmm, address[] calldata _tokens, uint8[] calldata _decimals, uint72 _minBorrow, bytes calldata) external virtual override {
        cfmm = _cfmm;
        tokens_ = _tokens;
        decimals_ = _decimals;
        tester = msg.sender;
        owner = msg.sender;
    }

    function getLatestCFMMBalances() external virtual override view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply) {
        cfmmReserves = new uint128[](2);
        cfmmReserves[0] = uint128(1000 * 1e18);
        cfmmReserves[1] = uint128(100000 * 1e18);
        cfmmInvariant = 10000 * 1e18;
        cfmmTotalSupply = 10000 * 1e18;
    }

    function getPoolBalances() external virtual override view returns(uint128[] memory tokenBalances, uint256 lpTokenBalance, uint256 lpTokenBorrowed,
        uint256 lpTokenBorrowedPlusInterest, uint256 borrowedInvariant, uint256 lpInvariant) {
        lpTokenBalance = 5000 * 1e18;
    }
}

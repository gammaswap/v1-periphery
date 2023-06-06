// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "@gammaswap/v1-core/contracts/interfaces/periphery/ISendTokensCallback.sol";
import "./ITestGammaPoolFactory.sol";
import "./TERC20.sol";

contract TestGammaPool is IGammaPool, TERC20 {

    address public override cfmm;
    address[] public tokens_;
    uint8[] public decimals_;
    uint16 immutable public override protocolId;
    address immutable public override factory;
    address immutable public override longStrategy;
    address immutable public override shortStrategy;
    address immutable public override liquidationStrategy;

    address public tester;
    address public owner;

    constructor(uint16 _protocolId, address _factory, address _longStrategy, address _shortStrategy, address _liquidationStrategy) TERC20("TestGammaPool","TGP-V1") {
        protocolId = _protocolId;
        factory = _factory;
        longStrategy = _longStrategy;
        shortStrategy = _shortStrategy;
        liquidationStrategy = _liquidationStrategy;
    }

    function initialize(address _cfmm, address[] calldata _tokens, uint8[] calldata _decimals, bytes calldata) external virtual override {
        cfmm = _cfmm;
        tokens_ = _tokens;
        decimals_ = _decimals;
        tester = ITestGammaPoolFactory(msg.sender).tester();
        owner = msg.sender;
        _mint(tester, 100000 * (10 ** 18));
    }

    function tokens() external virtual override view returns(address[] memory){
        return tokens_;
    }

    function getLoans(uint256, uint256, bool) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        return(new IGammaPool.LoanData[](0));
    }

    function getLoansById(uint256[] calldata tokenIds, bool) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        _loans = new IGammaPool.LoanData[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            if(tokenIds[i] > 0) {
                _loans[i] = loan(i);
            }
        }
    }

    function getLoanCount() external virtual override view returns(uint256) {
        return 0;
    }

    function canLiquidate(uint256 tokenId) external virtual view returns(bool) {
        return false;
    }

    function getPoolBalances() external virtual override view returns(uint128[] memory tokenBalances, uint256 lpTokenBalance, uint256 lpTokenBorrowed,
        uint256 lpTokenBorrowedPlusInterest, uint256 borrowedInvariant, uint256 lpInvariant) {
        return(new uint128[](1), 1, 2, 3, 4, 5);
    }

    function getCFMMBalances() external virtual override view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply) {
        return(new uint128[](2), 12, 13);
    }

    function getRates() external virtual override view returns(uint256 accFeeIndex, uint256 lastCFMMFeeIndex, uint256 lastBlockNumber) {
        return(9, 91, 14);
    }

    function getLatestCFMMBalances() external virtual override view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply) {
        return(new uint128[](2), 2, 3);
    }

    function getLastCFMMPrice() external view returns(uint256) {
        return 7;
    }

    function getConstantPoolData() external view returns(PoolData memory data) {
        return _getPoolData();
    }

    function getLatestPoolData() external view returns(PoolData memory data) {
        return _getPoolData();
    }

    function getPoolData() external virtual override view returns(PoolData memory data) {
        return _getPoolData();
    }

    function _getPoolData() internal virtual view returns(PoolData memory data) {
        data.poolId = address(this);
        data.protocolId = protocolId;
        data.longStrategy = longStrategy;
        data.shortStrategy = shortStrategy;
        data.liquidationStrategy = liquidationStrategy;
        data.cfmm = cfmm;
        data.LAST_BLOCK_NUMBER = 14;
        data.factory = factory;
        data.LP_TOKEN_BALANCE = 1;
        data.LP_TOKEN_BORROWED = 2;
        data.LP_TOKEN_BORROWED_PLUS_INTEREST = 3;
        data.BORROWED_INVARIANT = 4;
        data.LP_INVARIANT = 5;
        data.accFeeIndex = 9;
        data.lastCFMMInvariant = 12;
        data.lastCFMMTotalSupply = 13;
        data.totalSupply = totalSupply();
        data.decimals = decimals_;
        data.tokens = tokens_;
        data.TOKEN_BALANCE = new uint128[](1);
        data.CFMM_RESERVES = new uint128[](2);
    }

    function getTokensMetaData() external view returns(address[] memory _tokens, string[] memory _symbols, string[] memory _names, uint8[] memory _decimals) {
        return(new address[](1),new string[](2),new string[](3),new uint8[](4));
    }

    function testSendTokensCallback(address posAddr, address[] calldata _tokens, uint256[] calldata amounts, address payee, bytes calldata data) external virtual {
        ISendTokensCallback(posAddr).sendTokensCallback(_tokens, amounts, payee, data);
    }

    //Short Gamma
    function depositNoPull(address) external virtual override returns(uint256 shares) {
        shares = 15;
    }

    function withdrawNoPull(address) external virtual override returns(uint256 assets) {
        assets = 16;
    }

    function withdrawReserves(address) external virtual override returns (uint256[] memory reserves, uint256 assets) {
        reserves = new uint256[](3);
        reserves[0] = 200;
        reserves[1] = 300;
        reserves[2] = 400;
        assets = 17;
    }

    function depositReserves(address to, uint256[] calldata, uint256[] calldata, bytes calldata) external virtual override returns(uint256[] memory reserves, uint256 shares) {
        reserves = new uint256[](4);
        shares = 18;
        _mint(to, shares);
    }

    function getLatestCFMMReserves() external virtual override view returns(uint128[] memory cfmmReserves) {
        return new uint128[](2);
    }

    //Long Gamma
    function createLoan() external virtual override returns(uint256 tokenId) {
        tokenId = 19 + block.number * 100;
    }

    function loan(uint256) public virtual override view returns(IGammaPool.LoanData memory _loanData) {
        _loanData.id = 20;
        _loanData.poolId = cfmm;
        _loanData.tokensHeld = new uint128[](5);
        _loanData.liquidity = 21;
        _loanData.lpTokens = 22;
        _loanData.rateIndex = 23;
        _loanData.initLiquidity = 24;
        _loanData.tokenId = 25;
    }

    function borrowLiquidity(uint256, uint256, uint256[] calldata) external virtual override returns(uint256 liquidityBorrowed, uint256[] memory amounts) {
        liquidityBorrowed = 23;
        amounts = new uint256[](2);
    }

    function repayLiquidity(uint256, uint256, uint256[] calldata fees, uint256, address) external virtual override returns(uint256 liquidityPaid, uint256[] memory amounts) {
        liquidityPaid = 24 + fees.length + (fees.length == 2 ? fees[0] + fees[1] : 0);
        amounts = new uint256[](2);
    }

    function increaseCollateral(uint256, uint256[] calldata) external virtual override returns(uint128[] memory tokensHeld) {
        tokensHeld = new uint128[](6);
    }

    function decreaseCollateral(uint256, uint128[] calldata, address, uint256[] calldata) external virtual override returns(uint128[] memory tokensHeld) {
        tokensHeld = new uint128[](7);
    }

    function rebalanceCollateral(uint256, int256[] calldata, uint256[] calldata) external virtual override returns(uint128[] memory tokensHeld) {
        tokensHeld = new uint128[](2);
    }

    function liquidate(uint256, int256[] calldata, uint256[] calldata) external override virtual returns(uint256 loanLiquidity, uint256[] memory refund) {
        return (1, new uint256[](2));
    }

    function liquidateWithLP(uint256) external override virtual returns(uint256 loanLiquidity, uint256[] memory refund) {
        return (2, new uint256[](2));
    }

    function batchLiquidations(uint256[] calldata) external override virtual returns(uint256 totalLoanLiquidity, uint256 totalCollateral, uint256[] memory refund) {
        return (3, 4, new uint256[](2));
    }

    function validateCFMM(address[] calldata, address, bytes calldata) external override pure returns(address[] memory) {
        return (new address[](2));
    }

    function updatePool(uint256 tokenId) external returns(uint256, uint256) {
        return(5, 6);
    }

    function getLatestRates() external virtual view returns(RateData memory data) {
        data.accFeeIndex = 1;
        data.lastCFMMFeeIndex = 2;
        data.lastFeeIndex = 3;
        data.borrowRate = 4;
        data.lastBlockNumber = 5;
        data.currBlockNumber = 6;
    }

    function skim(address) external override {
    }

    function sync() external override {
    }

    function calcDeltasForRatio(uint128[] memory tokensHeld, uint128[] memory reserves, uint256[] calldata ratio) external override virtual view returns(int256[] memory deltas) {
        deltas = new int256[](6);
        deltas[0] = -int128(tokensHeld[0]);
        deltas[1] = int128(tokensHeld[1]);
        deltas[2] = int128(reserves[0]);
        deltas[3] = int128(reserves[1]);
        deltas[4] = int256(ratio[0]);
        deltas[5] = int256(ratio[1]);
    }

    function calcDeltasToClose(uint128[] memory tokensHeld, uint128[] memory reserves, uint256 liquidity, uint256 collateralId) external override virtual view returns(int256[] memory deltas) {
        deltas = new int256[](6);
        deltas[0] = -int128(tokensHeld[0]);
        deltas[1] = int128(tokensHeld[1]);
        deltas[2] = int128(reserves[0]);
        deltas[3] = int128(reserves[1]);
        deltas[4] = int256(liquidity);
        deltas[5] = int256(collateralId);
    }

    function rateParamsStore() external view returns(address) {
        return factory;
    }

    function validateParameters(bytes calldata _data) external view returns(bool) {
        return true;
    }

}

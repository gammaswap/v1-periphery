// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

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
    address immutable public override borrowStrategy;
    address immutable public override repayStrategy;
    address immutable public override rebalanceStrategy;
    address immutable public override shortStrategy;
    address immutable public override singleLiquidationStrategy;
    address immutable public override batchLiquidationStrategy;
    address immutable public override viewer;

    address public tester;
    address public owner;

    constructor(uint16 protocolId_, address factory_,  address borrowStrategy_, address repayStrategy_, address rebalanceStrategy_,
        address shortStrategy_, address singleLiquidationStrategy_, address batchLiquidationStrategy_, address viewer_) TERC20("TestGammaPool","TGP-V1") {
        protocolId = protocolId_;
        factory = factory_;
        borrowStrategy = borrowStrategy_;
        repayStrategy = repayStrategy_;
        rebalanceStrategy = rebalanceStrategy_;
        shortStrategy = shortStrategy_;
        singleLiquidationStrategy = singleLiquidationStrategy_;
        batchLiquidationStrategy = batchLiquidationStrategy_;
        viewer = viewer_;
    }

    function initialize(address _cfmm, address[] calldata _tokens, uint8[] calldata _decimals, uint72 _minBorrow, bytes calldata) external virtual override {
        cfmm = _cfmm;
        tokens_ = _tokens;
        decimals_ = _decimals;
        tester = ITestGammaPoolFactory(msg.sender).tester();
        owner = msg.sender;
        _mint(tester, 100000 * (10 ** 18));
    }

    function setPoolParams(uint16 origFee, uint8 extSwapFee, uint8 emaMultiplier, uint8 minUtilRate1, uint8 minUtilRate2, uint16 feeDivisor, uint8 liquidationFee, uint8 ltvThreshold, uint72 minBorrow) external virtual override {

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
        data.borrowStrategy = borrowStrategy;
        data.repayStrategy = repayStrategy;
        data.rebalanceStrategy = rebalanceStrategy;
        data.shortStrategy = shortStrategy;
        data.singleLiquidationStrategy = singleLiquidationStrategy;
        data.batchLiquidationStrategy = batchLiquidationStrategy;
        data.cfmm = cfmm;
        data.LAST_BLOCK_NUMBER = 14;
        data.factory = factory;
        data.paramsStore = factory;
        data.currBlockNumber = uint40(block.number);
        data.LP_TOKEN_BALANCE = 1;
        data.LP_TOKEN_BORROWED = 2;
        data.LP_TOKEN_BORROWED_PLUS_INTEREST = 3;
        data.BORROWED_INVARIANT = 4;
        data.LP_INVARIANT = 5;
        data.totalSupply = totalSupply();
        data.TOKEN_BALANCE = new uint128[](1);
        data.tokens = tokens_;
        data.decimals = decimals_;
        data.accFeeIndex = 9;
        data.origFee = 10;
        data.extSwapFee = 11;
        data.lastCFMMFeeIndex = 14;
        data.lastCFMMInvariant = 12;
        data.lastCFMMTotalSupply = 13;
        data.CFMM_RESERVES = new uint128[](2);
        data.emaUtilRate = 15;
        data.emaMultiplier = 16;
        data.minUtilRate1 = 17;
        data.minUtilRate2 = 17;
        data.feeDivisor = 18;
        data.ltvThreshold = 19;
        data.liquidationFee = 20;
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
    function createLoan(uint16) external virtual override returns(uint256 tokenId) {
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

    function borrowLiquidity(uint256, uint256, uint256[] calldata) external virtual override returns(uint256 liquidityBorrowed, uint256[] memory amounts, uint128[] memory tokensHeld) {
        liquidityBorrowed = 23;
        amounts = new uint256[](2);
        tokensHeld = new uint128[](2);
    }

    function repayLiquidity(uint256, uint256, uint256, address) external virtual override returns(uint256 liquidityPaid, uint256[] memory amounts) {
        liquidityPaid = 24;
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

    function liquidate(uint256) external override virtual returns(uint256 loanLiquidity, uint256 refund) {
        return (1, 2);
    }

    function liquidateWithLP(uint256) external override virtual returns(uint256 loanLiquidity, uint256[] memory refund) {
        return (2, new uint256[](2));
    }

    function batchLiquidations(uint256[] calldata) external override virtual returns(uint256 totalLoanLiquidity, uint256[] memory refund) {
        return (3, new uint256[](2));
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

    function rateParamsStore() external view returns(address) {
        return factory;
    }

    function validateParameters(bytes calldata _data) external view returns(bool) {
        return true;
    }

    function repayLiquidityWithLP(uint256 tokenId, uint256 collateralId, address to) external returns(uint256 liquidityPaid, uint128[] memory tokensHeld) {
        liquidityPaid = 2400 + collateralId;
        tokensHeld = new uint128[](2);
    }

    function repayLiquiditySetRatio(uint256 tokenId, uint256 liquidity, uint256[] calldata ratio) external virtual override returns(uint256 liquidityPaid, uint256[] memory amounts) {
        liquidityPaid = 240;
        amounts = new uint256[](2);
    }

    function getLoanData(uint256 _tokenId) external override virtual view returns(LoanData memory _loanData) {

    }

    function calcInvariant(uint128[] memory tokensHeld) external override virtual view returns(uint256) {

    }
}

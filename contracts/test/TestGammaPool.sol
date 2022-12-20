// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "../interfaces/ISendTokensCallback.sol";
import "./ITestGammaPoolFactory.sol";

contract TestGammaPool is IGammaPool, ERC20 {

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

    constructor(uint16 _protocolId, address _factory, address _longStrategy, address _shortStrategy, address _liquidationStrategy) ERC20("TestGammaPool","TGP-V1") {
        protocolId = _protocolId;
        factory = _factory;
        longStrategy = _longStrategy;
        shortStrategy = _shortStrategy;
        liquidationStrategy = _liquidationStrategy;
    }

    function initialize(address _cfmm, address[] calldata _tokens, uint8[] calldata _decimals) external virtual override {
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

    function getPoolBalances() external virtual override view returns(uint128[] memory tokenBalances, uint256 lpTokenBalance, uint256 lpTokenBorrowed,
        uint256 lpTokenBorrowedPlusInterest, uint256 borrowedInvariant, uint256 lpInvariant) {
        return(new uint128[](1), 1, 2, 3, 4, 5);
    }

    function getCFMMBalances() external virtual override view returns(uint128[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply) {
        return(new uint128[](2), 12, 13);
    }

    function getRates() external virtual override view returns(uint256 accFeeIndex, uint256 lastBlockNumber) {
        return(9, 14);
    }

    function getPoolData() external virtual override view returns(PoolData memory data) {
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

    function testSendTokensCallback(address posAddr, address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external virtual {
        ISendTokensCallback(posAddr).sendTokensCallback(tokens, amounts, payee, data);
    }

    //Short Gamma
    function depositNoPull(address to) external virtual override returns(uint256 shares) {
        shares = 15;
    }

    function withdrawNoPull(address to) external virtual override returns(uint256 assets) {
        assets = 16;
    }

    function withdrawReserves(address to) external virtual override returns (uint256[] memory reserves, uint256 assets) {
        reserves = new uint256[](3);
        reserves[0] = 200;
        reserves[1] = 300;
        reserves[2] = 400;
        assets = 17;
    }

    function depositReserves(address to, uint256[] calldata amountsDesired, uint256[] calldata amountsMin, bytes calldata data) external virtual override returns(uint256[] memory reserves, uint256 shares) {
        reserves = new uint256[](4);
        shares = 18;
    }

    //Long Gamma
    function getCFMMPrice() external virtual override view returns(uint256 price) {
        return 1;
    }

    function createLoan() external virtual override returns(uint256 tokenId) {
        tokenId = 19;
    }

    function loan(uint256 tokenId) external virtual override view returns (uint256 id, address poolId,
        uint128[] memory tokensHeld, uint256 initLiquidity, uint256 liquidity, uint256 lpTokens, uint256 rateIndex) {
        id = 20;
        poolId = cfmm;
        tokensHeld = new uint128[](5);
        liquidity = 21;
        lpTokens = 22;
        rateIndex = 23;
        initLiquidity = 24;
    }

    function borrowLiquidity(uint256 tokenId, uint256 lpTokens) external virtual override returns(uint256[] memory amounts) {
        amounts = new uint256[](2);
    }

    function repayLiquidity(uint256 tokenId, uint256 liquidity) external virtual override returns(uint256 liquidityPaid, uint256[] memory amounts) {
        liquidityPaid = 24;
        amounts = new uint256[](2);
    }

    function increaseCollateral(uint256 tokenId) external virtual override returns(uint128[] memory tokensHeld) {
        tokensHeld = new uint128[](6);
    }

    function decreaseCollateral(uint256 tokenId, uint256[] calldata amounts, address to) external virtual override returns(uint128[] memory tokensHeld) {
        tokensHeld = new uint128[](7);
    }

    function rebalanceCollateral(uint256 tokenId, int256[] calldata deltas) external virtual override returns(uint128[] memory tokensHeld) {
        tokensHeld = new uint128[](2);
    }

    function liquidate(uint256 tokenId, bool isRebalance, int256[] calldata deltas) external override virtual returns(uint256[] memory refund) {
        return new uint256[](2);
    }

    function liquidateWithLP(uint256 tokenId) external override virtual returns(uint256[] memory refund) {
        return new uint256[](2);
    }

    function batchLiquidations(uint256[] calldata tokenIds) external override virtual returns(uint256[] memory refund) {
        return new uint256[](2);
    }

    function validateCFMM(address[] calldata _tokens, address _cfmm) external override view returns(address[] memory tokens, uint8[] memory decimals) {
        return (new address[](2), new uint8[](2));
    }
}

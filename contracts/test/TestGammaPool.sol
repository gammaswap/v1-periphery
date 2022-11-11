pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "../interfaces/ISendTokensCallback.sol";
import "./ITestGammaPoolFactory.sol";

contract TestGammaPool is IGammaPool, ERC20 {

    address public override cfmm;
    uint24 public override protocolId;
    address public override protocol;
    address[] public tokens_;
    address public override factory;
    address public override longStrategy;
    address public override shortStrategy;

    address public tester;
    address public owner;

    constructor() ERC20("TestGammaPool","TGP-V1"){
        factory = msg.sender;
        (cfmm, protocolId, tokens_, protocol) = ITestGammaPoolFactory(msg.sender).parameters();
        longStrategy = ITestGammaPoolFactory(msg.sender).longStrategy();
        shortStrategy = ITestGammaPoolFactory(msg.sender).shortStrategy();
        tester = ITestGammaPoolFactory(msg.sender).tester();
        owner = msg.sender;
        _mint(tester, 100000 * (10 ** 18));//mint to tester
    }

    function tokens() external virtual override view returns(address[] memory){
        return tokens_;
    }


    function getPoolBalances() external virtual override view returns(uint256[] memory tokenBalances, uint256 lpTokenBalance, uint256 lpTokenBorrowed,
        uint256 lpTokenBorrowedPlusInterest, uint256 lpTokenTotal, uint256 borrowedInvariant, uint256 lpInvariant, uint256 totalInvariant) {
        return(new uint256[](1), 1, 2, 3, 4, 5, 6, 7);
    }

    function getCFMMBalances() external virtual override view returns(uint256[] memory cfmmReserves, uint256 cfmmInvariant, uint256 cfmmTotalSupply) {
        return(new uint256[](2), 12, 13);
    }


    function getRates() external virtual override view returns(uint256 borrowRate, uint256 accFeeIndex, uint256 lastFeeIndex, uint256 lastCFMMFeeIndex, uint256 lastBlockNumber) {
        return(8, 9, 10, 11, 14);
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
        uint256[] memory tokensHeld, uint256 initLiquidity, uint256 liquidity, uint256 lpTokens, uint256 rateIndex) {
        id = 20;
        poolId = cfmm;
        tokensHeld = new uint256[](5);
        liquidity = 21;
        rateIndex = 22;
        initLiquidity = 23;
    }

    function increaseCollateral(uint256 tokenId) external virtual override returns(uint256[] memory tokensHeld) {
        tokensHeld = new uint256[](6);
    }

    function decreaseCollateral(uint256 tokenId, uint256[] calldata amounts, address to) external virtual override returns(uint256[] memory tokensHeld) {
        tokensHeld = new uint256[](7);
    }

    function borrowLiquidity(uint256 tokenId, uint256 lpTokens) external virtual override returns(uint256[] memory amounts) {
        amounts = new uint256[](8);
    }

    function repayLiquidity(uint256 tokenId, uint256 liquidity) external virtual override returns(uint256 liquidityPaid, uint256[] memory amounts) {
        liquidityPaid = 24;
        amounts = new uint256[](9);
    }

    function rebalanceCollateral(uint256 tokenId, int256[] calldata deltas) external virtual override returns(uint256[] memory tokensHeld) {
        tokensHeld = new uint256[](10);
    }

    function liquidate(uint256 tokenId, bool isRebalance, int256[] calldata deltas) external override virtual returns(uint256[] memory refund) {
        return new uint256[](2);
    }

    function liquidateWithLP(uint256 tokenId) external override virtual returns(uint256[] memory refund) {
        return new uint256[](2);
    }
}

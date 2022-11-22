// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;
pragma abicoder v2;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "./interfaces/IPositionManager.sol";
import "./interfaces/ISendTokensCallback.sol";
import "./base/Transfers.sol";
import "./base/GammaPoolERC721.sol";

contract PositionManager is IPositionManager, ISendTokensCallback, Transfers, GammaPoolERC721 {

    error Forbidden();
    error Expired();
    error AmountsMin();

    address public owner;

    address public immutable override factory;

    modifier isAuthorizedForToken(uint256 tokenId) {
        checkAuthorization(tokenId);
        _;
    }

    modifier isExpired(uint256 deadline) {
        checkDeadline(deadline);
        _;
    }

    function checkAuthorization(uint256 tokenId) internal view {
        if(!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Forbidden();
        }
    }

    function checkDeadline(uint256 deadline) internal view {
        if(deadline < block.timestamp) {
            revert Expired();
        }
    }

    constructor(address _factory, address _WETH) GammaPoolERC721("PosMgr", "PM-V1") Transfers(_WETH) {
        factory = _factory;
        owner = msg.sender;
    }

    function getGammaPoolAddress(address cfmm, uint16 protocolId) internal virtual view returns(address) {
        return AddressCalculator.calcAddress(factory, protocolId, AddressCalculator.getGammaPoolKey(cfmm, protocolId));
    }

    function sendTokensCallback(address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external virtual override {
        SendTokensCallbackData memory decoded = abi.decode(data, (SendTokensCallbackData));
        if(msg.sender != getGammaPoolAddress(decoded.cfmm, decoded.protocolId)) {
            revert Forbidden();
        }
        sendTokens(tokens, amounts, decoded.payer, payee);
    }

    function sendTokens(address[] memory tokens, uint256[] calldata amounts, address payer, address payee) internal virtual {
        uint256 len = tokens.length;
        for (uint i = 0; i < len; i++) {
            if (amounts[i] > 0 ) send(tokens[i], payer, payee, amounts[i]);
        }
    }

    // **** Short Gamma **** //
    function depositNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(params.cfmm, msg.sender, gammaPool, params.lpTokens); // send lp tokens to pool
        shares = IGammaPool(gammaPool).depositNoPull(params.to);
        emit DepositNoPull(gammaPool, shares);
    }

    function withdrawNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 assets) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(gammaPool, msg.sender, gammaPool, params.lpTokens); // send gs tokens to pool
        assets = IGammaPool(gammaPool).withdrawNoPull(params.to);
        emit WithdrawNoPull(gammaPool, assets);
    }

    function depositReserves(DepositReservesParams calldata params) external virtual override isExpired(params.deadline) returns(uint256[] memory reserves, uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (reserves, shares) = IGammaPool(gammaPool)
        .depositReserves(params.to, params.amountsDesired, params.amountsMin,
            abi.encode(SendTokensCallbackData({cfmm: params.cfmm, protocolId: params.protocolId, payer: msg.sender})));
        emit DepositReserve(gammaPool, reserves.length, shares);
    }

    function withdrawReserves(WithdrawReservesParams calldata params) external virtual override isExpired(params.deadline) returns (uint256[] memory reserves, uint256 assets) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(gammaPool, msg.sender, gammaPool, params.amount); // send gs tokens to pool
        (reserves, assets) = IGammaPool(gammaPool).withdrawReserves(params.to);
        checkMinReserves(reserves, params.amountsMin);
        emit WithdrawReserve(gammaPool, reserves.length, assets);
    }

    // **** LONG GAMMA **** //
    function logLoan(address gammaPool, uint256 tokenId, address owner) internal virtual {
        uint128[] memory tokensHeld;
        uint256 initLiquidity;
        uint256 liquidity;
        uint256 lpTokens;
        (, ,  tokensHeld, initLiquidity, liquidity, lpTokens, ) = IGammaPool(gammaPool).loan(tokenId);
        emit LoanUpdate(tokenId, gammaPool, owner, tokensHeld, liquidity, lpTokens, initLiquidity, IGammaPool(gammaPool).getCFMMPrice());
    }

    function checkMinReserves(uint256[] memory amounts, uint256[] memory amountsMin) internal virtual pure {
        uint256 len = amounts.length;
        for (uint24 i = 0; i < len; i++) {
            if(amounts[i] < amountsMin[i]) {
                revert AmountsMin();
            }
        }
    }

    function checkMinCollateral(uint128[] memory amounts, uint128[] memory amountsMin) internal virtual pure {
        uint256 len = amounts.length;
        for (uint24 i = 0; i < len; i++) {
            if(amounts[i] < amountsMin[i]) {
                revert AmountsMin();
            }
        }
    }

    function createLoan(address cfmm, uint16 protocolId, address to, uint256 deadline) external virtual override isExpired(deadline) returns(uint256 tokenId) {
        address gammaPool = getGammaPoolAddress(cfmm, protocolId);
        tokenId = IGammaPool(gammaPool).createLoan();
        _safeMint(to, tokenId);
        emit CreateLoan(gammaPool, to, tokenId);
        logLoan(gammaPool, tokenId, to);
    }

    function borrowLiquidity(BorrowLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        amounts = IGammaPool(gammaPool).borrowLiquidity(params.tokenId, params.lpTokens);
        checkMinReserves(amounts, params.minBorrowed);
        emit BorrowLiquidity(gammaPool, params.tokenId, amounts.length);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    function repayLiquidity(RepayLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (liquidityPaid, amounts) = IGammaPool(gammaPool).repayLiquidity(params.tokenId, params.liquidity);
        checkMinReserves(amounts, params.minRepaid);
        emit RepayLiquidity(gammaPool, params.tokenId, liquidityPaid, amounts.length);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    function increaseCollateral(AddRemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        sendTokens(IGammaPool(gammaPool).tokens(), params.amounts, msg.sender, gammaPool);
        tokensHeld = IGammaPool(gammaPool).increaseCollateral(params.tokenId);
        emit IncreaseCollateral(gammaPool, params.tokenId, tokensHeld.length);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    function decreaseCollateral(AddRemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld){
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = IGammaPool(gammaPool).decreaseCollateral(params.tokenId, params.amounts, params.to);
        emit DecreaseCollateral(gammaPool, params.tokenId, tokensHeld.length);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    function rebalanceCollateral(RebalanceCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = IGammaPool(gammaPool).rebalanceCollateral(params.tokenId, params.deltas);
        checkMinCollateral(tokensHeld, params.minCollateral);
        emit RebalanceCollateral(gammaPool, params.tokenId, tokensHeld.length);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }
}
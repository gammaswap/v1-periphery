// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IPositionManager.sol";
import "./interfaces/IGammaPool.sol";
import "./interfaces/IGammaPoolFactory.sol";
import "./interfaces/ISendTokensCallback.sol";
import "./libraries/PoolAddress.sol";
import "./base/Transfers.sol";
import "./base/GammaPoolERC721.sol";

contract PositionManager is IPositionManager, ISendTokensCallback, Transfers, GammaPoolERC721 {

    address public owner;

    address public immutable override factory;

    bytes32 public initCodeHash;

    modifier isAuthorizedForToken(uint256 tokenId) {
        checkAuthorization(tokenId);
        _;
    }

    modifier isExpired(uint256 deadline) {
        checkDeadline(deadline);
        _;
    }

    function checkAuthorization(uint256 tokenId) internal view {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'FORBIDDEN');
    }

    function checkDeadline(uint256 deadline) internal view {
        require(deadline >= block.timestamp, 'EXPIRED');
    }

    constructor(address _factory, address _WETH, bytes32 _initCodeHash) GammaPoolERC721("PosMgr", "PM-V1") Transfers(_WETH) {
        factory = _factory;
        owner = msg.sender;
        initCodeHash = _initCodeHash;
    }

    function sendTokensCallback(address[] calldata tokens, uint256[] calldata amounts, address payee, bytes calldata data) external virtual override {
        SendTokensCallbackData memory decoded = abi.decode(data, (SendTokensCallbackData));
        require(msg.sender == PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(decoded.cfmm, decoded.protocol), initCodeHash), 'FORBIDDEN');

        for(uint i = 0; i < tokens.length; i++) {
            if(amounts[i] > 0) send(tokens[i], decoded.payer, payee, amounts[i]);
        }
    }

    // **** Short Gamma **** //
    function depositNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 shares) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        send(params.cfmm, msg.sender, gammaPool, params.lpTokens); // send lp tokens to pool
        shares = IGammaPool(gammaPool).depositNoPull(params.to);
        emit DepositNoPull(gammaPool, shares);
    }

    function withdrawNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 assets) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        send(gammaPool, msg.sender, gammaPool, params.lpTokens); // send gs tokens to pool
        assets = IGammaPool(gammaPool).withdrawNoPull(params.to);
        emit WithdrawNoPull(gammaPool, assets);
    }

    function depositReserves(DepositReservesParams calldata params) external virtual override isExpired(params.deadline) returns(uint256[] memory reserves, uint256 shares) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        (reserves, shares) = IGammaPool(gammaPool)
        .depositReserves(params.cfmm, params.amountsDesired, params.amountsMin,
            abi.encode(SendTokensCallbackData({cfmm: params.cfmm, protocol: params.protocol, payer: msg.sender})));
        emit DepositReserves(gammaPool, reserves.length, shares);
    }

    function withdrawReserves(WithdrawReservesParams calldata params) external virtual override isExpired(params.deadline) returns (uint256[] memory reserves, uint256 assets) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        send(gammaPool, msg.sender, gammaPool, params.amount); // send gs tokens to pool
        (reserves, assets) = IGammaPool(gammaPool).withdrawReserves(params.to);
        for (uint i = 0; i < reserves.length; i++) {
            require(reserves[i] >= params.amountsMin[i], '< min');
        }
        emit WithdrawReserves(gammaPool, reserves.length, assets);
    }

    // **** LONG GAMMA **** //
    function createLoan(address cfmm, uint24 protocol, address to, uint256 deadline) external virtual override isExpired(deadline) returns(uint256 tokenId) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(cfmm, protocol), initCodeHash);
        tokenId = IGammaPool(gammaPool).createLoan();
        _safeMint(to, tokenId);
        emit CreateLoan(gammaPool, tokenId);
    }

    function loan(address cfmm, uint24 protocol, uint256 tokenId) external virtual override view returns (uint256 id, address poolId, uint256[] memory tokensHeld,
        uint256 liquidity, uint256 rateIndex, uint256 blockNum) {
        return IGammaPool(PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(cfmm, protocol), initCodeHash)).loan(tokenId);
    }

    function borrowLiquidity(BorrowLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256[] memory amounts) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        amounts = IGammaPool(gammaPool).borrowLiquidity(params.tokenId, params.lpTokens);
        emit BorrowLiquidity(gammaPool, params.tokenId, amounts.length);
    }

    function repayLiquidity(RepayLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint256 lpTokensPaid, uint256[] memory amounts) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        (liquidityPaid, lpTokensPaid, amounts) = IGammaPool(gammaPool).repayLiquidity(params.tokenId, params.liquidity);
        emit RepayLiquidity(gammaPool, params.tokenId, liquidityPaid, lpTokensPaid, amounts.length);
    }

    function increaseCollateral(AddRemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint256[] memory tokensHeld) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        address[] memory _tokens = IGammaPool(gammaPool).tokens();
        for (uint i = 0; i < _tokens.length; i++) {
            if (params.amounts[i] > 0 ) send(_tokens[i], msg.sender, gammaPool, params.amounts[i]);
        }
        tokensHeld = IGammaPool(gammaPool).increaseCollateral(params.tokenId);
        emit IncreaseCollateral(gammaPool, params.tokenId, tokensHeld.length);
    }

    function decreaseCollateral(AddRemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint256[] memory tokensHeld){
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        tokensHeld = IGammaPool(gammaPool).decreaseCollateral(params.tokenId, params.amounts, params.to);
        emit DecreaseCollateral(gammaPool, params.tokenId, tokensHeld.length);
    }

    function rebalanceCollateral(RebalanceCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint256[] memory tokensHeld) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        tokensHeld = IGammaPool(gammaPool).rebalanceCollateral(params.tokenId, params.deltas);
        emit RebalanceCollateral(gammaPool, params.tokenId, tokensHeld.length);
    }

    function rebalanceCollateralWithLiquidity(RebalanceCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint256[] memory tokensHeld) {
        address gammaPool = PoolAddress.calcAddress(factory, PoolAddress.getPoolKey(params.cfmm, params.protocol), initCodeHash);
        tokensHeld = IGammaPool(gammaPool).rebalanceCollateralWithLiquidity(params.tokenId, params.liquidity);
        emit RebalanceCollateralWithLiquidity(gammaPool, params.tokenId, tokensHeld.length);
    }
}
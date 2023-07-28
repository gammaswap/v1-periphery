// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "./interfaces/IPositionManager.sol";
import "./interfaces/IPriceStore.sol";
import "./base/Transfers.sol";
import "./base/GammaPoolERC721.sol";
import "./base/GammaPoolQueryableLoans.sol";

/// @title PositionManager, concrete implementation of IPositionManager
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Periphery contract used to aggregate function calls to a GammaPool and give NFT (ERC721) functionality to loans
/// @notice Loans created through PositionManager become NFTs and can only be managed through PositionManager
/// @dev PositionManager is owner of loan and user is owner of NFT that represents loan in a GammaPool
contract PositionManager is IPositionManager, Transfers, GammaPoolQueryableLoans {

    error Forbidden();
    error Expired();
    error AmountsMin();

    string constant private _name = "PositionManager";
    string constant private _symbol = "PM-V1";

    /// @dev See {IPositionManager-factory}.
    address public immutable override factory;

    address public priceStore;

    modifier isAuthorizedForToken(uint256 tokenId) {
        checkAuthorization(tokenId);
        _;
    }

    modifier isExpired(uint256 deadline) {
        checkDeadline(deadline);
        _;
    }

    /// @dev Revert if msg.sender is not owner of loan or does not have permission to manage loan by checking NFT that represents loan
    /// @param tokenId - id that identifies loan
    function checkAuthorization(uint256 tokenId) internal view {
        if(!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Forbidden();
        }
    }

    /// @dev Revert if transaction already expired
    /// @param deadline - timestamp after which transaction is considered expired
    function checkDeadline(uint256 deadline) internal view {
        if(deadline < block.timestamp) {
            revert Expired();
        }
    }

    /// @dev Initializes the contract by setting `factory`, `WETH`, and `dataStore`.
    constructor(address _factory, address _WETH, address _dataStore, address _priceStore) Transfers(_WETH) GammaPoolQueryableLoans(_dataStore) {
        factory = _factory;
        priceStore = _priceStore;
    }

    /// @dev See {IERC721Metadata-name}.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @param _dataStore - address of contract holding loan information for queries
    function setDataStore(address _dataStore) external virtual {
        dataStore = _dataStore;
    }

    /// @param _priceStore - address of contract holding price information for queries
    function setPriceStore(address _priceStore) external virtual {
        priceStore = _priceStore;
    }

    /// @dev See {ITransfers-getGammaPoolAddress}.
    function getGammaPoolAddress(address cfmm, uint16 protocolId) internal virtual override view returns(address) {
        return AddressCalculator.calcAddress(factory, protocolId, AddressCalculator.getGammaPoolKey(cfmm, protocolId));
    }

    // **** Short Gamma **** //

    /// @dev See {IPositionManager-depositNoPull}.
    function depositNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(params.cfmm, msg.sender, gammaPool, params.lpTokens); // send lp tokens to pool
        shares = IGammaPool(gammaPool).depositNoPull(params.to);
        emit DepositNoPull(gammaPool, shares);
    }

    /// @dev See {IPositionManager-withdrawNoPull}.
    function withdrawNoPull(DepositWithdrawParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 assets) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(gammaPool, msg.sender, gammaPool, params.lpTokens); // send gs tokens to pool
        assets = IGammaPool(gammaPool).withdrawNoPull(params.to);
        emit WithdrawNoPull(gammaPool, assets);
    }

    /// @dev See {IPositionManager-depositReserves}.
    function depositReserves(DepositReservesParams calldata params) external virtual override isExpired(params.deadline) returns(uint256[] memory reserves, uint256 shares) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (reserves, shares) = IGammaPool(gammaPool)
        .depositReserves(params.to, params.amountsDesired, params.amountsMin,
            abi.encode(SendTokensCallbackData({cfmm: params.cfmm, protocolId: params.protocolId, payer: msg.sender})));
        emit DepositReserve(gammaPool, reserves, shares);
    }

    /// @dev See {IPositionManager-withdrawReserves}.
    function withdrawReserves(WithdrawReservesParams calldata params) external virtual override isExpired(params.deadline) returns (uint256[] memory reserves, uint256 assets) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(gammaPool, msg.sender, gammaPool, params.amount); // send gs tokens to pool
        (reserves, assets) = IGammaPool(gammaPool).withdrawReserves(params.to);
        checkMinReserves(reserves, params.amountsMin);
        emit WithdrawReserve(gammaPool, reserves, assets);
    }

    // **** LONG GAMMA **** //

    function logPrice(address gammaPool) external virtual {
        if(IGammaPoolFactory(factory).getKey(gammaPool) > 0) {
            _logPrice(gammaPool);
        }
    }

    function _logPrice(address gammaPool) internal virtual {
        if(priceStore != address(0)) {
            IPriceStore(priceStore).addPriceInfo(gammaPool);
        }
    }

    /// @notice Slippage protection for uint256[] array. If amounts < amountsMin, less was obtained than expected
    /// @dev Used to check quantities of tokens not used as collateral
    /// @param amounts - array containing uint256 amounts received from GammaPool
    /// @param amountsMin - minimum amounts acceptable to be received from uint256 before reverting transaction
    function checkMinReserves(uint256[] memory amounts, uint256[] memory amountsMin) internal virtual pure {
        uint256 len = amounts.length;
        for (uint256 i; i < len;) {
            if(amounts[i] < amountsMin[i]) {
                revert AmountsMin();
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Slippage protection for uint128[] array. If amounts < amountsMin, less was obtained than expected
    /// @dev Used to check quantities of tokens used as collateral
    /// @param amounts - array containing uint128 amounts received from GammaPool
    /// @param amountsMin - minimum amounts acceptable to be received from uint128 before reverting transaction
    function checkMinCollateral(uint128[] memory amounts, uint128[] memory amountsMin) internal virtual pure {
        uint256 len = amounts.length;
        for (uint256 i; i < len;) {
            if(amounts[i] < amountsMin[i]) {
                revert AmountsMin();
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Create a loan in GammaPool and turn it into an NFT issued to address `to`
    /// @dev Loans created here are actually owned by PositionManager and wrapped as an NFT issued to address `to`
    /// @param gammaPool - address of GammaPool we are creating gammaloan for
    /// @param to - recipient of NFT token
    /// @param refId - reference Id of loan observer
    /// @return tokenId - tokenId from creation of loan
    function createLoan(address gammaPool, address to, uint16 refId) internal virtual returns(uint256 tokenId) {
        tokenId = IGammaPool(gammaPool).createLoan(refId);
        mintQueryableLoan(gammaPool, tokenId, to);
        emit CreateLoan(gammaPool, to, tokenId, refId);
    }

    /// @dev Increase loan collateral by depositing more reserve tokens
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param amounts - amounts of reserve tokens sent to gammaPool
    /// @param ratio - ratio of loan collateral to be maintained after increasing collateral
    /// @return tokensHeld - new loan collateral token amounts
    function increaseCollateral(address gammaPool, uint256 tokenId, uint256[] calldata amounts, uint256[] memory ratio) internal virtual returns(uint128[] memory tokensHeld) {
        sendTokens(IGammaPool(gammaPool).tokens(), msg.sender, gammaPool, amounts);
        tokensHeld = IGammaPool(gammaPool).increaseCollateral(tokenId, ratio);
        emit IncreaseCollateral(gammaPool, tokenId, tokensHeld, amounts);
    }

    /// @dev Decrease loan collateral by withdrawing reserve tokens
    /// @param gammaPool - address of GammaPool of the loan
    /// @param to - address of recipient of amounts withdrawn from GammaPool
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param amounts - amounts of reserve tokens requesting to withdraw from loan
    /// @param ratio - ratio of loan collateral to be maintained after decreasing collateral
    /// @return tokensHeld - new loan collateral token amounts
    function decreaseCollateral(address gammaPool, address to, uint256 tokenId, uint128[] memory amounts, uint256[] memory ratio) internal virtual returns(uint128[] memory tokensHeld) {
        tokensHeld = IGammaPool(gammaPool).decreaseCollateral(tokenId, amounts, to, ratio);
        emit DecreaseCollateral(gammaPool, tokenId, tokensHeld, amounts);
    }

    /// @dev Re-balance loan collateral tokens by swapping one for another
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param deltas - amount to swap of one token at index for another (>0 buy, <0 sell). Must have at least one index field be 0
    /// @param ratio - ratio to rebalance collateral
    /// @param minCollateral - minimum amount of expected collateral after re-balancing. Used for slippage control
    /// @return tokensHeld - new loan collateral token amounts
    function rebalanceCollateral(address gammaPool, uint256 tokenId, int256[] memory deltas, uint256[] calldata ratio, uint128[] memory minCollateral) internal virtual returns(uint128[] memory tokensHeld) {
        tokensHeld = IGammaPool(gammaPool).rebalanceCollateral(tokenId, deltas, ratio);
        checkMinCollateral(tokensHeld, minCollateral);
        emit RebalanceCollateral(gammaPool, tokenId, tokensHeld);
    }

    /// @dev Borrow liquidity from GammaPool, can be used with a newly created loan or a loan already holding some liquidity debt
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param lpTokens - amount of CFMM LP tokens to short (borrow liquidity)
    /// @param ratio - ratio to rebalance collateral after borrowing
    /// @param minBorrowed - minimum expected amounts of reserve tokens to receive as collateral for `lpTokens` short. Used for slippage control
    /// @param maxBorrowed - max borrowed liquidity
    /// @return liquidityBorrowed - liquidity borrowed in exchange for CFMM LP tokens (`lpTokens`)
    /// @return amounts - amounts of reserve tokens received to hold as collateral for shorting `lpTokens`
    function borrowLiquidity(address gammaPool, uint256 tokenId, uint256 lpTokens, uint256[] memory ratio, uint256[] calldata minBorrowed, uint256 maxBorrowed) internal virtual returns(uint256 liquidityBorrowed, uint256[] memory amounts) {
        (liquidityBorrowed, amounts) = IGammaPool(gammaPool).borrowLiquidity(tokenId, lpTokens, ratio);
        require(liquidityBorrowed <= maxBorrowed, "MAX_BORROWED");
        checkMinReserves(amounts, minBorrowed);
        emit BorrowLiquidity(gammaPool, tokenId, liquidityBorrowed, amounts);
    }

    /// @dev Repay liquidity debt from GammaPool
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param liquidity - desired liquidity to pay
    /// @param fees - fee on transfer for tokens[i]. Send empty array or array of zeroes if no token in pool has fee on transfer
    /// @param collateralId - index of collateral token + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @param minRepaid - minimum amount of expected collateral to have used as payment. Used for slippage control
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function repayLiquidity(address gammaPool, uint256 tokenId, uint256 liquidity, uint256[] calldata fees, uint256 collateralId, address to, uint256[] calldata minRepaid) internal virtual returns (uint256 liquidityPaid, uint256[] memory amounts) {
        (liquidityPaid, amounts) = IGammaPool(gammaPool).repayLiquidity(tokenId, liquidity, fees, collateralId, to);
        checkMinReserves(amounts, minRepaid);
        emit RepayLiquidity(gammaPool, tokenId, liquidityPaid, amounts);
    }

    /// @dev Repay liquidity debt from GammaPool
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param liquidity - desired liquidity to pay
    /// @param fees - fee on transfer for tokens[i]. Send empty array or array of zeroes if no token in pool has fee on transfer
    /// @param ratio - weights of collateral after repaying liquidity
    /// @param minRepaid - minimum amount of expected collateral to have used as payment. Used for slippage control
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return amounts - reserve tokens used to pay liquidity debt
    function repayLiquiditySetRatio(address gammaPool, uint256 tokenId, uint256 liquidity, uint256[] calldata fees, uint256[] calldata ratio, uint256[] calldata minRepaid) internal virtual returns (uint256 liquidityPaid, uint256[] memory amounts) {
        (liquidityPaid, amounts) = IGammaPool(gammaPool).repayLiquiditySetRatio(tokenId, liquidity, fees, ratio);
        checkMinReserves(amounts, minRepaid);
        emit RepayLiquiditySetRatio(gammaPool, tokenId, liquidityPaid, amounts);
    }

    /// @dev Repay liquidity debt from GammaPool with LP Tokens
    /// @param gammaPool - address of GammaPool of the loan
    /// @param tokenId - id to identify the loan in the GammaPool
    /// @param collateralId - index of collateral token + 1
    /// @param to - if repayment type requires withdrawal, the address that will receive the funds. Otherwise can be zero address
    /// @param minCollateral - minimum collateral amounts in loan after repayment
    /// @param lpTokens - CFMM LP tokens used to repay liquidity debt
    /// @return liquidityPaid - actual liquidity debt paid
    /// @return tokensHeld - reserve tokens used to pay liquidity debt
    function repayLiquidityWithLP(address gammaPool, uint256 tokenId, uint256 collateralId, address to, uint128[] memory minCollateral, uint256 lpTokens) internal virtual returns (uint256 liquidityPaid, uint128[] memory tokensHeld) {
        (liquidityPaid, tokensHeld) = IGammaPool(gammaPool).repayLiquidityWithLP(tokenId, collateralId, to);
        checkMinCollateral(tokensHeld, minCollateral);
        emit RepayLiquidityWithLP(gammaPool, tokenId, liquidityPaid, tokensHeld, lpTokens);
    }

    // Individual Function Calls

    /// @dev See {IPositionManager-createLoan}.
    function createLoan(uint16 protocolId, address cfmm, address to, uint16 refId, uint256 deadline) external virtual override isExpired(deadline) returns(uint256 tokenId) {
        address gammaPool = getGammaPoolAddress(cfmm, protocolId);
        tokenId = createLoan(gammaPool, to, refId);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-borrowLiquidity}.
    function borrowLiquidity(BorrowLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (liquidityBorrowed, amounts) = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens, params.ratio, params.minBorrowed, params.maxBorrowed);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-repayLiquidity}.
    function repayLiquidity(RepayLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        if(params.isRatio) {
            (liquidityPaid, amounts) = repayLiquiditySetRatio(gammaPool, params.tokenId, params.liquidity, params.fees, params.ratio, params.minRepaid);
        } else {
            (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, params.fees, params.collateralId, params.to, params.minRepaid);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-repayLiquidityWithLP}.
    function repayLiquidityWithLP(RepayLiquidityWithLPParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        send(params.cfmm, msg.sender, gammaPool, params.lpTokens);
        (liquidityPaid, tokensHeld) = repayLiquidityWithLP(gammaPool, params.tokenId, params.collateralId, params.to, params.minCollateral, params.lpTokens);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-increaseCollateral}.
    function increaseCollateral(AddCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts, params.ratio);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-decreaseCollateral}.
    function decreaseCollateral(RemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld){
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.amounts, params.ratio);
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-rebalanceCollateral}.
    function rebalanceCollateral(RebalanceCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = rebalanceCollateral(gammaPool, params.tokenId, params.deltas, params.ratio, params.minCollateral);
        _logPrice(gammaPool);
    }

    // Multi Function Calls

    /// @dev See {IPositionManager-createLoanBorrowAndRebalance}.
    function createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 tokenId, uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokenId = createLoan(gammaPool, params.to, params.refId);
        tokensHeld = increaseCollateral(gammaPool, tokenId, params.amounts, new uint256[](0));
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts) = borrowLiquidity(gammaPool, tokenId, params.lpTokens, params.ratio, params.minBorrowed, params.maxBorrowed);
        }
        _logPrice(gammaPool);
    }

    /// @dev See {IPositionManager-borrowAndRebalance}.
    function borrowAndRebalance(BorrowAndRebalanceParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld, uint256 liquidityBorrowed, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        if(params.amounts.length != 0) {
            tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts,
                params.lpTokens != 0 ? new uint256[](0) : params.ratio);
        }
        if(params.lpTokens != 0) {
            (liquidityBorrowed, amounts) = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens,
                params.withdraw.length != 0 ? new uint256[](0) : params.ratio, params.minBorrowed, params.maxBorrowed);
        }
        if(params.withdraw.length != 0) {
            tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw, params.ratio);
        }
        _logPrice(gammaPool);
    }
}
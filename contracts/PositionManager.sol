// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";
import "@gammaswap/v1-core/contracts/libraries/AddressCalculator.sol";
import "./interfaces/IPositionManager.sol";
import "./base/Transfers.sol";
import "./base/GammaPoolERC721.sol";

/// @title PositionManager, concrete implementation of IPositionManager
/// @author Daniel D. Alcarraz
/// @notice Periphery contract used to aggregate function calls to a GammaPool and give NFT (ERC721) functionality to loans
/// @notice Loans created through PositionManager become NFTs and can only be managed through PositionManager
/// @dev PositionManager is owner of loan and user is owner of NFT that represents loan in a GammaPool
contract PositionManager is IPositionManager, Transfers, GammaPoolERC721 {

    error Forbidden();
    error Expired();
    error AmountsMin();

    string constant private _name = "PositionManager";
    string constant private _symbol = "PM-V1";

    /// @dev See {IPositionManager-factory}.
    address public immutable override factory;

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

    /// @dev Initializes the contract by setting `factory`, and `WETH`.
    constructor(address _factory, address _WETH) Transfers(_WETH) {
        factory = _factory;
    }

    /// @dev See {IERC721Metadata-name}.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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
        emit DepositReserve(gammaPool, reserves.length, shares);
    }

    /// @dev See {IPositionManager-withdrawReserves}.
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
        emit LoanUpdate(tokenId, gammaPool, owner, tokensHeld, liquidity, lpTokens, initLiquidity, IGammaPool(gammaPool).getLatestCFMMReserves());
    }

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

    function createLoan(address gammaPool, address to) internal virtual returns(uint256 tokenId) {
        tokenId = IGammaPool(gammaPool).createLoan();
        _safeMint(to, tokenId);
        emit CreateLoan(gammaPool, to, tokenId);
    }

    function increaseCollateral(address gammaPool, uint256 tokenId, uint256[] calldata amounts) internal virtual returns(uint128[] memory tokensHeld) {
        sendTokens(IGammaPool(gammaPool).tokens(), msg.sender, gammaPool, amounts);
        tokensHeld = IGammaPool(gammaPool).increaseCollateral(tokenId);
        emit IncreaseCollateral(gammaPool, tokenId, tokensHeld.length);
    }

    function borrowLiquidity(address gammaPool, uint256 tokenId, uint256 lpTokens, uint256[] calldata minBorrowed) internal virtual returns(uint256[] memory amounts) {
        amounts = IGammaPool(gammaPool).borrowLiquidity(tokenId, lpTokens);
        checkMinReserves(amounts, minBorrowed);
        emit BorrowLiquidity(gammaPool, tokenId, amounts.length);
    }

    function rebalanceCollateral(address gammaPool, uint256 tokenId, int256[] calldata deltas, uint128[] calldata minCollateral) internal virtual returns(uint128[] memory tokensHeld) {
        tokensHeld = IGammaPool(gammaPool).rebalanceCollateral(tokenId, deltas);
        checkMinCollateral(tokensHeld, minCollateral);
        emit RebalanceCollateral(gammaPool, tokenId, tokensHeld.length);
    }

    function repayLiquidity(address gammaPool, uint256 tokenId, uint256 liquidity, uint256[] calldata minRepaid) internal virtual returns (uint256 liquidityPaid, uint256[] memory amounts) {
        (liquidityPaid, amounts) = IGammaPool(gammaPool).repayLiquidity(tokenId, liquidity);
        checkMinReserves(amounts, minRepaid);
        emit RepayLiquidity(gammaPool, tokenId, liquidityPaid, amounts.length);
    }

    function decreaseCollateral(address gammaPool, address to, uint256 tokenId, uint256[] calldata amounts) internal virtual returns(uint128[] memory tokensHeld) {
        tokensHeld = IGammaPool(gammaPool).decreaseCollateral(tokenId, amounts, to);
        emit DecreaseCollateral(gammaPool, tokenId, tokensHeld.length);
    }

    // Individual Function Calls

    /// @dev See {IPositionManager-createLoan}.
    function createLoan(uint16 protocolId, address cfmm, address to, uint256 deadline) external virtual override isExpired(deadline) returns(uint256 tokenId) {
        address gammaPool = getGammaPoolAddress(cfmm, protocolId);
        tokenId = createLoan(gammaPool, to);
        logLoan(gammaPool, tokenId, to);
    }

    /// @dev See {IPositionManager-borrowLiquidity}.
    function borrowLiquidity(BorrowLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        amounts = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens, params.minBorrowed);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    /// @dev See {IPositionManager-repayLiquidity}.
    function repayLiquidity(RepayLiquidityParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns (uint256 liquidityPaid, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, params.minRepaid);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    /// @dev See {IPositionManager-increaseCollateral}.
    function increaseCollateral(AddRemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    /// @dev See {IPositionManager-decreaseCollateral}.
    function decreaseCollateral(AddRemoveCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld){
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.amounts);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    /// @dev See {IPositionManager-rebalanceCollateral}.
    function rebalanceCollateral(RebalanceCollateralParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokensHeld = rebalanceCollateral(gammaPool, params.tokenId, params.deltas, params.minCollateral);
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    // Multi Function Calls

    /// @dev See {IPositionManager-createLoanBorrowAndRebalance}.
    function createLoanBorrowAndRebalance(CreateLoanBorrowAndRebalanceParams calldata params) external virtual override isExpired(params.deadline) returns(uint256 tokenId, uint128[] memory tokensHeld, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        tokenId = createLoan(gammaPool, params.to);
        tokensHeld = increaseCollateral(gammaPool, tokenId, params.amounts);
        if(params.lpTokens != 0) {
            amounts = borrowLiquidity(gammaPool, tokenId, params.lpTokens, params.minBorrowed);
        }
        if(params.deltas.length != 0) {
            tokensHeld = rebalanceCollateral(gammaPool, tokenId, params.deltas, params.minCollateral);
        }
        logLoan(gammaPool, tokenId, params.to);
    }

    /// @dev See {IPositionManager-borrowAndRebalance}.
    function borrowAndRebalance(BorrowAndRebalanceParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        if(params.amounts.length != 0) {
            tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts);
        }
        if(params.lpTokens != 0) {
            amounts = borrowLiquidity(gammaPool, params.tokenId, params.lpTokens, params.minBorrowed);
        }
        if(params.deltas.length != 0) {
            tokensHeld = rebalanceCollateral(gammaPool, params.tokenId, params.deltas, params.minCollateral);
        }
        if(params.withdraw.length != 0) {
            tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw);
        }
        logLoan(gammaPool, params.tokenId, msg.sender);
    }

    /// @dev See {IPositionManager-rebalanceRepayAndWithdraw}.
    function rebalanceRepayAndWithdraw(RebalanceRepayAndWithdrawParams calldata params) external virtual override isAuthorizedForToken(params.tokenId) isExpired(params.deadline) returns(uint128[] memory tokensHeld, uint256 liquidityPaid, uint256[] memory amounts) {
        address gammaPool = getGammaPoolAddress(params.cfmm, params.protocolId);
        if(params.amounts.length != 0 && params.amounts[0] != 0) {
            tokensHeld = increaseCollateral(gammaPool, params.tokenId, params.amounts);
        }
        if(params.deltas.length != 0 && params.deltas[0] != 0) {
            tokensHeld = rebalanceCollateral(gammaPool, params.tokenId, params.deltas, params.minCollateral);
        }
        if(params.liquidity != 0) {
            (liquidityPaid, amounts) = repayLiquidity(gammaPool, params.tokenId, params.liquidity, params.minRepaid);
        }
        if(params.withdraw.length != 0) {
            tokensHeld = decreaseCollateral(gammaPool, params.to, params.tokenId, params.withdraw);
        }
        logLoan(gammaPool, params.tokenId, msg.sender);
    }
}
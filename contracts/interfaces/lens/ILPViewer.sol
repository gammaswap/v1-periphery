// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Interface for LPViewer
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface used to send tokens and clear tokens and Ether from a contract
interface ILPViewer {

    /// @dev Event emitted when a staking contract is set up for a pool to track LP deposits in staking contract
    /// @param pool - address of pool to get information for
    /// @param rewardTracker - rewardTracker of staking contract that accepts pool as deposit token
    event RegisterRewardTracker(address indexed pool, address rewardTracker);

    /// @dev Event emitted when a staking contract is deregistered for a pool because we won't track staked
    /// @dev positions for that pool anymore
    /// @param pool - address of pool to get information for
    /// @param rewardTracker - rewardTracker of staking contract that accepts pool as deposit token
    event UnregisterRewardTracker(address indexed pool, address rewardTracker);

    /// @dev Register a reward tracker for a pool so that we can get the staked amount for a user
    /// @param pool - address of pool to get information for
    /// @param rewardTracker - rewardTracker of staking contract that accepts pool as deposit token
    function registerRewardTracker(address pool, address rewardTracker) external;

    /// @dev Unregister a reward tracker for a pool
    /// @param pool - address of pool to get information for
    /// @param rewardTracker - rewardTracker of staking contract that accepts pool as deposit token
    function unregisterRewardTracker(address pool, address rewardTracker) external;

    /// @dev token quantity and GS LP balance information for a user in a given pool
    /// @param user - address of user to get information for
    /// @param pool - address of pool to get information for
    /// @return lpBalance - GS LP Balance of user
    function getStakedLPBalance(address user, address pool) external view returns(uint256 lpBalance);

    /// @dev NonStatic call to get total token balances in pools array belonging to a user.
    /// @dev The index of the tokenBalances array will match the index of the tokens array.
    /// @notice there may be more tokens than there are pools. E.g. WETH/USDC => 2 tokens and 1 pool
    /// @param user - address of user to get information for
    /// @param pools - array of addresses of pools to check token balance information in
    /// @return tokens - addresses of tokens in pools array
    /// @return tokenBalances - total balances of each token in tokens array belonging to user across all pools
    /// @return size - number of elements in the tokens array
    function tokenBalancesInPoolsNonStatic(address user, address[] calldata pools) external returns(address[] memory tokens,
        uint256[] memory tokenBalances, uint256 size);

    /// @dev Static call to get total token balances in pools array belonging to a user.
    /// @dev The index of the tokenBalances array will match the index of the tokens array.
    /// @notice there may be more tokens than there are pools. E.g. WETH/USDC => 2 tokens and 1 pool
    /// @param user - address of user to get information for
    /// @param pools - array of addresses of pools to check token balance information in
    /// @return tokens - addresses of tokens in pools array
    /// @return tokenBalances - total balances of each token in tokens array belonging to user across all pools
    /// @return size - number of elements in the tokens array
    function tokenBalancesInPools(address user, address[] calldata pools) external view returns(address[] memory tokens,
        uint256[] memory tokenBalances, uint256 size);

    /// @dev token quantity and GS LP balance information for a user in a given pool
    /// @param user - address of user to get information for
    /// @param pool - address of pool to get information for
    /// @return token0 - address of token0 in pool
    /// @return token1 - address of token1 in pool
    /// @return token0Balance - balance of token0 in pool belonging to user
    /// @return token1Balance - balance of token1 in pool belonging to user
    /// @return lpBalance - GS LP Balance of user
    function lpBalanceByPool(address user, address pool) external view returns(address token0, address token1,
        uint256 token0Balance, uint256 token1Balance, uint256 lpBalance);

    /// @dev token quantities and GS LP balance information for a user per pool
    /// @dev the index of each array matches the index of each pool in hte pools array
    /// @param user - address of user to get information for
    /// @param pools - addresses of pools to get information for
    /// @return token0 - addresses of token0 per pool
    /// @return token1 - addresses of token1 per pool
    /// @return token0Balance - array of balances of token0 per pool belonging to user
    /// @return token1Balance - array of balances of token1 per pool belonging to user
    /// @return lpBalance - array of GS LP Balances of user per pool
    function lpBalanceByPools(address user, address[] calldata pools) external view returns(address[] memory token0, address[] memory token1,
        uint256[] memory token0Balance, uint256[] memory token1Balance, uint256[] memory lpBalance);
}

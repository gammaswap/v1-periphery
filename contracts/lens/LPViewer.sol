// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gammaswap/v1-core/contracts/interfaces/IGammaPool.sol";

contract LPViewer {

    mapping(address => uint256) tokenIndex;

    constructor(){
    }

    function tokenBalancesInPoolsNonStatic(address user, address[] calldata pools) public virtual returns(address[] memory tokens, uint256[] memory tokenBalances, uint256 size) {
        tokens = new address[](pools.length * 2);
        tokenBalances = new uint256[](pools.length * 2);
        size = 0;

        for(uint256 i; i < pools.length;) {
            address[] memory _tokens = IGammaPool(pools[i]).tokens();
            if(tokenIndex[_tokens[0]] == 0) {
                tokenIndex[_tokens[0]] = size + 1;
                tokens[size] = _tokens[0];
                unchecked{
                    ++size;
                }
            }
            if(tokenIndex[_tokens[1]] == 0) {
                tokenIndex[_tokens[1]] = size + 1;
                tokens[size] = _tokens[1];
                unchecked{
                    ++size;
                }
            }
            unchecked{
                ++i;
            }
        }

        for(uint256 i; i < pools.length;) {
            (address token0, address token1, uint256 token0Balance, uint256 token1Balance,) = _lpBalanceByPool(user, pools[i]);
            tokenBalances[tokenIndex[token0] - 1] += token0Balance;
            tokenBalances[tokenIndex[token1] - 1] += token1Balance;
            unchecked{
                ++i;
            }
        }

        for(uint256 i; i < size;) {
            tokenIndex[tokens[i]] = 0; // clear the mapping
            unchecked{
                ++i;
            }
        }
    }

    function tokenBalancesInPools(address user, address[] calldata pools) public virtual view returns(address[] memory tokens, uint256[] memory tokenBalances, uint256 size) {
        tokens = new address[](pools.length * 2);
        tokenBalances = new uint256[](pools.length * 2);
        size = 0;
        for(uint256 i; i < pools.length;) {
            address[] memory _tokens = IGammaPool(pools[i]).tokens();
            bool found0 = false;
            bool found1 = false;
            for(uint256 j; j < tokens.length;) {
                if(tokens[j] == _tokens[0]) {
                    found0 = true;
                } else if(tokens[j] == _tokens[1]) {
                    found1 = true;
                } else if(tokens[j] == address(0)) {
                    if(!found0) {
                        tokens[j] = _tokens[0];
                        found0 = true;
                        unchecked {
                            ++size;
                        }
                    } else if(!found1) {
                        tokens[j] = _tokens[1];
                        found1 = true;
                        unchecked {
                            ++size;
                        }
                    }
                }
                if(found0 && found1) {
                    break;
                }
                unchecked{
                    ++j;
                }
            }
            unchecked{
                ++i;
            }
        }

        for(uint256 i; i < pools.length;) {
            (address token0, address token1, uint256 token0Balance, uint256 token1Balance,) = _lpBalanceByPool(user, pools[i]);
            uint256 found = 0;
            for(uint256 j; j < tokens.length;) {
                if(token0 == tokens[j]) {
                    tokenBalances[j] += token0Balance;
                    found++;
                } else if(token1 == tokens[j]) {
                    tokenBalances[j] += token1Balance;
                    found++;
                }
                if(found == 2) {
                    break;
                }
                unchecked{
                    ++j;
                }
            }
            unchecked{
                ++i;
            }
        }
    }

    function lpBalanceByPool(address user, address pool) public virtual view returns(address token0, address token1,
        uint256 token0Balance, uint256 token1Balance, uint256 lpBalance) {
        return _lpBalanceByPool(user, pool);
    }

    function _lpBalanceByPool(address user, address pool) internal virtual view returns(address token0, address token1,
        uint256 token0Balance, uint256 token1Balance, uint256 lpBalance) {
        lpBalance = IERC20(pool).balanceOf(user);
        uint256 lpTotalSupply = IERC20(pool).totalSupply();

        address[] memory tokens = IGammaPool(pool).tokens();
        token0 = tokens[0];
        token1 = tokens[1];

        (uint128[] memory cfmmReserves,, uint256 cfmmTotalSupply) = IGammaPool(pool).getLatestCFMMBalances();
        (,uint256 lpTokenBalance,,,,) = IGammaPool(pool).getPoolBalances();

        token0Balance = lpBalance * lpTokenBalance * uint256(cfmmReserves[0]) / (cfmmTotalSupply * lpTotalSupply);
        token1Balance = lpBalance * lpTokenBalance * uint256(cfmmReserves[1]) / (cfmmTotalSupply * lpTotalSupply);
    }

    function lpBalanceByPools(address user, address[] calldata pools) public virtual view returns(address[] memory token0,
        address[] memory token1, uint256[] memory token0Balance, uint256[] memory token1Balance, uint256[] memory lpBalance) {
        uint256 len = pools.length;
        token0 = new address[](len);
        token1 = new address[](len);
        token0Balance = new uint256[](len);
        token1Balance= new uint256[](len) ;
        lpBalance = new uint256[](len);
        for(uint256 i; i < len;) {
            (token0[i], token1[i], token0Balance[i], token1Balance[i], lpBalance[i]) = _lpBalanceByPool(user, pools[i]);
            unchecked{
                ++i;
            }
        }
    }
}

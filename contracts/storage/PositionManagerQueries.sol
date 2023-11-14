// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gammaswap/v1-core/contracts/interfaces/IGammaPoolFactory.sol";
import "@gammaswap/v1-core/contracts/interfaces/IPoolViewer.sol";
import "../libraries/QueryUtils.sol";
import "../interfaces/IPositionManagerQueries.sol";
import "../interfaces/IGammaPoolQueryableLoans.sol";
import "./LoanStore.sol";

/// @title Implementation of IPositionManagerQueries
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Implements external functions used by PositionManager to query pools and loans
/// @dev These are all view functions that read from storage of different GammaPools and GammaPoolFactory
contract PositionManagerQueries is IPositionManagerQueries, LoanStore {

    /// @dev address of GammaPool factory contract
    address private immutable factory;

    /// @dev Initializes the contract by setting `_factory`, and `_owner`.
    constructor(address _factory, address _owner) LoanStore(_owner) {
        factory = _factory;
    }

    /// @dev See {IPositionManagerQueries-getLoansByOwnerAndPool}.
    function getLoansByOwnerAndPool(address owner, address gammaPool, uint256 start, uint256 end) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        uint256[] memory _tokenIds = loansByOwnerAndPool[owner][gammaPool];
        (uint256 _start, uint256 _end, uint256 _size) = QueryUtils.getSearchParameters(start, end, _tokenIds.length);
        if(_size > 0) {
            uint256[] memory _tokenIdsReq = new uint256[](_size);
            uint256 k = 0;
            for(uint256 i = _start; i <= _end;) {
                if(_tokenIds[i] > 0) {
                    _tokenIdsReq[k] = _tokenIds[i];
                }
                unchecked {
                    ++k;
                    ++i;
                }
            }
            _loans = IPoolViewer(IGammaPool(gammaPool).viewer()).getLoansById(gammaPool, _tokenIdsReq, false);
        } else {
            _loans = new IGammaPool.LoanData[](0);
        }
    }

    /// @dev See {IPositionManagerQueries-getLoansByOwner}.
    function getLoansByOwner(address owner, uint256 start, uint256 end) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        uint256[] memory _loanList = loansByOwner[owner];
        (uint256 _start, uint256 _end, uint256 _size) = QueryUtils.getSearchParameters(start, end, _loanList.length);
        if(_size > 0) {
            _loans = new IGammaPool.LoanData[](_size);
            uint256 k = 0;
            for(uint256 i = _start; i <= _end;) {
                uint256 _tokenId = _loanList[i];
                if(_tokenId > 0) {
                    address pool = loanToInfo[_tokenId].pool;
                    _loans[k] = IPoolViewer(IGammaPool(pool).viewer()).loan(pool, _tokenId);
                }
                unchecked {
                    ++k;
                    ++i;
                }
            }
        } else {
            _loans = new IGammaPool.LoanData[](0);
        }
    }

    /// @dev See {IPositionManagerQueries-getPools}.
    function getPools(uint256 start, uint256 end) external override virtual view returns(IGammaPool.PoolData[] memory _pools) {
        address[] memory poolAddresses = IGammaPoolFactory(factory).getPools(start, end);
        _pools = new IGammaPool.PoolData[](poolAddresses.length);
        for(uint256 i = 0; i < poolAddresses.length;) {
            _pools[i] = IPoolViewer(IGammaPool(poolAddresses[i]).viewer()).getLatestPoolData(poolAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IPositionManagerQueries-getPoolsByAddresses}.
    function getPoolsByAddresses(address[] calldata poolAddresses) external override virtual view returns(IGammaPool.PoolData[] memory _pools) {
        _pools = new IGammaPool.PoolData[](poolAddresses.length);
        for(uint256 i = 0; i < poolAddresses.length;) {
            _pools[i] = IPoolViewer(IGammaPool(poolAddresses[i]).viewer()).getLatestPoolData(poolAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IPositionManagerQueries-getPoolsWithOwnerLPBalance}.
    function getPoolsWithOwnerLPBalance(address[] calldata poolAddresses, address owner) external view returns(IGammaPool.PoolData[] memory _pools, uint256[] memory _balances) {
        _pools = new IGammaPool.PoolData[](poolAddresses.length);
        _balances = new uint256[](poolAddresses.length);
        for(uint256 i = 0; i < poolAddresses.length;) {
            _balances[i] = IERC20(poolAddresses[i]).balanceOf(owner);
            _pools[i] = IPoolViewer(IGammaPool(poolAddresses[i]).viewer()).getLatestPoolData(poolAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }
}

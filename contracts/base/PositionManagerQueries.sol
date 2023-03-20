// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPositionManagerQueries.sol";

/// @title Implementation of IPositionManagerQueries
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Implements external functions used by PositionManager to query pools and loans
/// @dev These are all view functions that read from storage of different GammaPools and GammaPoolFactory
abstract contract PositionManagerQueries is IPositionManagerQueries {

    mapping(address => LoanInfo[]) private loansByOwner;
    mapping(address => mapping(address => uint256[])) private loansByOwnerAndPool;

    address private immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    /// @dev Add loan to mappings by user so that they can be queried
    /// @param pool - pool loan identified by `tokenId` belongs to
    /// @param tokenId - unique identifier of loan
    /// @param owner - owner of loan
    function addLoanToOwner(address pool, uint256 tokenId, address owner) internal virtual {
        loansByOwnerAndPool[owner][pool].push(tokenId);
        loansByOwner[owner].push(LoanInfo({ poolId: pool, tokenId: tokenId }));
    }

    /// @notice Validate and get parameters to query loans or pools arrays. If query fails validation size is zero
    /// @dev Get search parameters to query array. If end > last index of array, cap it at array's last index
    /// @param start - start index of array
    /// @param end - end index array
    /// @param len - assumed length of array
    /// @return _start - start index of owner's loan array
    /// @return _end - end index of owner's loan array
    /// @return _size - expected number of results from query
    function getSearchParameters(uint256 start, uint256 end, uint256 len) internal virtual pure returns(uint256 _start, uint256 _end, uint256 _size) {
        if(len != 0 && start <= end && start <= len - 1) {
            _start = start;
            unchecked {
                uint256 _lastIdx = len - 1;
                _end = _lastIdx < end ? _lastIdx : end;
                _size = _end - _start + 1;
            }
        }
    }

    /// @dev See {IPositionManagerQueries-getLoansByOwnerAndPool}.
    function getLoansByOwnerAndPool(address owner, address gammaPool, uint256 start, uint256 end) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        uint256[] storage _tokenIds = loansByOwnerAndPool[owner][gammaPool];
        (uint256 _start, uint256 _end, uint256 _size) = getSearchParameters(start, end, _tokenIds.length);
        if(_size > 0) {
            _loans = new IGammaPool.LoanData[](_size);
            uint256 k = 0;
            for(uint256 i = _start; i <= _end;) {
                _loans[k] = IGammaPool(gammaPool).loan(_tokenIds[i]);
                unchecked {
                    k++;
                    i++;
                }
            }
        } else {
            _loans = new IGammaPool.LoanData[](0);
        }
    }

    /// @dev See {IPositionManagerQueries-getLoansByOwner}.
    function getLoansByOwner(address owner, uint256 start, uint256 end) external virtual override view returns(IGammaPool.LoanData[] memory _loans) {
        LoanInfo[] storage _loanInfoList = loansByOwner[owner];
        (uint256 _start, uint256 _end, uint256 _size) = getSearchParameters(start, end, _loanInfoList.length);
        if(_size > 0) {
            _loans = new IGammaPool.LoanData[](_size);
            uint256 k = 0;
            for(uint256 i = _start; i <= _end;) {
                _loans[k] = IGammaPool(_loanInfoList[i].poolId).loan(_loanInfoList[i].tokenId);
                unchecked {
                    k++;
                    i++;
                }
            }
        } else {
            _loans = new IGammaPool.LoanData[](0);
        }
    }

    /// @dev See {IPositionManagerQueries-getPools}.
    function getPools(uint256 start, uint256 end) external override virtual view returns(IGammaPool.PoolData[] memory _pools) {
        (address[] memory _poolAddresses,) = IGammaPoolFactory(factory).getPools(start, end);
        _pools = new IGammaPool.PoolData[](_poolAddresses.length);
        for(uint256 i = 0; i < _poolAddresses.length;) {
            _pools[i] = IGammaPool(_poolAddresses[i]).getLatestPoolData();
            unchecked {
                i++;
            }
        }
    }

    /// @dev See {IPositionManagerQueries-getPoolsByAddresses}.
    function getPoolsByAddresses(address[] calldata poolAddresses) external override virtual view returns(IGammaPool.PoolData[] memory _pools) {
        _pools = new IGammaPool.PoolData[](poolAddresses.length);
        for(uint256 i = 0; i < poolAddresses.length;) {
            _pools[i] = IGammaPool(poolAddresses[i]).getLatestPoolData();
            unchecked {
                i++;
            }
        }
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Library used to help with PositionManager queries
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Library performs approvals, transfers and views ERC20 state fields
library QueryUtils {
    /// @notice Validate and get parameters to query loans or pools arrays. If query fails validation size is zero
    /// @dev Get search parameters to query array. If end > last index of array, cap it at array's last index
    /// @param start - start index of array
    /// @param end - end index array
    /// @param len - assumed length of array
    /// @return _start - start index of owner's loan array
    /// @return _end - end index of owner's loan array
    /// @return _size - expected number of results from query
    function getSearchParameters(uint256 start, uint256 end, uint256 len) internal pure returns(uint256 _start, uint256 _end, uint256 _size) {
        if(len != 0 && start <= end && start <= len - 1) {
            _start = start;
            unchecked {
                uint256 _lastIdx = len - 1;
                _end = _lastIdx < end ? _lastIdx : end;
                _size = _end - _start + 1;
            }
        }
    }
}
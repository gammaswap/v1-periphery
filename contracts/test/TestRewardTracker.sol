// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gammaswap/v1-staking/contracts/RewardTracker.sol";

contract TestRewardTracker is RewardTracker {

    constructor(string memory _name, string memory _symbol) RewardTracker() {
        name = _name;
        symbol = _symbol;
    }

    function _stake(address _fundingAccount, address _account, address _depositToken, uint256 _amount) internal virtual override {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");

        IERC20(_depositToken).transferFrom(_fundingAccount, address(this), _amount);

        //_updateRewards(_account);

        stakedAmounts[_account] = stakedAmounts[_account] + _amount;
        depositBalances[_account][_depositToken] = depositBalances[_account][_depositToken] + _amount;
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken] + _amount;

        _mint(_account, _amount);

        emit Stake(_fundingAccount, _account, _depositToken, _amount);
    }

    function _unstake(address _account, address _depositToken, uint256 _amount, address _receiver) internal virtual override {
        require(_amount > 0, "RewardTracker: invalid _amount");

        //_updateRewards(_account);

        uint256 stakedAmount = stakedAmounts[_account];
        require(stakedAmount >= _amount, "RewardTracker: _amount exceeds stakedAmount");

        stakedAmounts[_account] = stakedAmount - _amount;

        uint256 depositBalance = depositBalances[_account][_depositToken];
        require(depositBalance >= _amount, "RewardTracker: _amount exceeds depositBalance");

        depositBalances[_account][_depositToken] = depositBalance - _amount;
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken] - _amount;

        _burn(_account, _amount);
        IERC20(_depositToken).transfer(_receiver, _amount);

        emit Unstake(_account, _depositToken, _amount, _receiver);
    }
}

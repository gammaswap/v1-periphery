// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../interfaces/external/IWETH.sol";

contract WETH9 is IWETH {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    mapping (address => uint)                       public  balance;
    mapping (address => mapping (address => uint))  public override allowance;

    receive() external payable {
        deposit();
    }
    
    function deposit() public payable override {
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    } 

    function withdraw(uint amount) public override {
        require(balance[msg.sender] >= amount);
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    function totalSupply() public view override returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint amount) public override returns (bool) {
        allowance[msg.sender][guy] = amount;
        emit Approval(msg.sender, guy, amount);
        return true;
    }

    function transfer(address to, uint amount) public override returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount)
        public
        override
        returns (bool)
    {
        require(balance[from] >= amount);

        if (from != msg.sender && allowance[from][msg.sender] != type(uint).max) {
            require(allowance[from][msg.sender] >= amount);
            allowance[from][msg.sender] -= amount;
        }

        balance[from] -= amount;
        balance[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }
}
pragma solidity ^0.8.0;

import "../interfaces/IGammaPoolFactory.sol";

interface ITestGammaPoolFactory is IGammaPoolFactory{
    function longStrategy() external view returns(address);
    function shortStrategy() external view returns(address);
    function tester() external view returns(address);
}

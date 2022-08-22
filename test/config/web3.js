/* global web3 */

const Web3 = require('web3');

const DEFAULT_PROVIDER_URL = 'http://localhost:8545';

const web3 = new Web3(DEFAULT_PROVIDER_URL);

function getWeb3 () {
  return web3;
}

module.exports = {
  getWeb3,
};

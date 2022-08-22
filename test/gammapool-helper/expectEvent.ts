import { ethers } from "hardhat";
import { expect } from "chai";

const web3 = require('../config/web3').getWeb3();

export async function inTransaction(txHash: any, emitter: any, eventName: any, eventArgs = {}) {
  const receipt = await ethers.provider.getTransactionReceipt(txHash);
  const logs = decodeLogs(receipt.logs, emitter, eventName);
  return inLogs(logs, eventName, eventArgs);
}

function decodeLogs(logs: any, emitter: any, eventName: any) {
  let abi: any;
  let address: any;
  if (isContract(emitter)) {
    abi = emitter.interface
    try {
      address = emitter.address
    } catch (error) {
      throw error
    }
  } else {
    throw new Error('Unknown contract object');
  }

  let eventABI = abi.fragments.filter((x: any) => x.type === 'event' && x.name === eventName);
  if (eventABI.length === 0) {
    throw new Error(`No ABI entry for event '${eventName}'`);
  } else if (eventABI.length > 1) {
    throw new Error(`Multiple ABI entries for event '${eventName}', only uniquely named events are supported`);
  }

  eventABI = eventABI[0];

  // The first topic will equal the hash of the event signature
  const eventSignature = `${eventName}(${eventABI.inputs.map((input: any) => input.type).join(',')})`;
  const eventTopic = web3.utils.sha3(eventSignature);

  // Only decode events of type 'EventName'
  return logs
    .filter((log: any) => log.topics.length > 0 && log.topics[0] === eventTopic && (!address || log.address === address))
    .map((log: any) => web3.eth.abi.decodeLog(eventABI.inputs, log.data, log.topics.slice(1)))
    .map((decoded: any) => ({ event: eventName, args: decoded }));
}

function inLogs (logs: any, eventName: any, eventArgs = {}) {
  const events = logs.filter((e: any) => e.event === eventName);
  expect(events.length > 0).to.equal(true, `No '${eventName}' events found`);

  const exception: any = [];
  const event = events.find(function (e: any) {
    for (const [k, v] of Object.entries(eventArgs)) {
      try {
        contains(e.args, k, v);
      } catch (error) {
        exception.push(error);
        return false;
      }
    }
    return true;
  });

  if (event === undefined) {
    throw exception[0];
  }

  return event;
}

function isContract (contract: any) {
  return 'interface' in contract && typeof contract.interface === 'object';
}

function contains (args: any, key: any, value: any) {
  expect(key in args).to.equal(true, `Event argument '${key}' not found`);

  if (value === null) {
    expect(args[key]).to.equal(null,
      `expected event argument '${key}' to be null but got ${args[key]}`);
  } else if (isBN(args[key]) || isBN(value)) {
    const actual = isBN(args[key]) ? args[key].toString() : args[key];
    const expected = isBN(value) ? value.toString() : value;
    expect(args[key]).to.equal(value,
      `expected event argument '${key}' to have value ${expected} but got ${actual}`);
  } else {
    expect(args[key]).to.be.deep.equal(value,
      `expected event argument '${key}' to have value ${value} but got ${args[key]}`);
  }
}

function isBN(num: any) {
  return ethers.BigNumber.isBigNumber(num);
}
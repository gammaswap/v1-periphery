import { ethers } from "hardhat";
import type { TestERC20 } from "../typechain/TestERC20";
const UniswapV2FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const UniswapV2PairJSON = require("@uniswap/v2-core/build/UniswapV2Pair.json");
import GammaPoolFactoryJSON from "../artifacts-core/contracts/GammaPoolFactory.sol/GammaPoolFactory.json";
import CPMMProtocolJSON from "../artifacts-core/contracts/protocols/CPMMProtocol.sol/CPMMProtocol.json";
import GammaPoolJSON from "../artifacts-core/contracts/GammaPool.sol/GammaPool.json";

// if there are any contract changes in core, ./artifacts-core needs to be 
// rebuilt and saved to this repo

async function main() {

  // deploy test tokens

  const [owner] = await ethers.getSigners();
  const TestERC20Contract = await ethers.getContractFactory("TestERC20");
  const tokenA = await TestERC20Contract.deploy("Test Token A", "TOKA");
  const tokenB = await TestERC20Contract.deploy("Test Token B", "TOKB");
  const tokenC = await TestERC20Contract.deploy("Test Token C", "TOKC");
  const WETH = await TestERC20Contract.deploy("WETH", "WETH");
  await tokenA.deployed();
  await tokenB.deployed();
  await tokenC.deployed();
  await WETH.deployed();
  console.log("tokenA Address >> " + tokenA.address);
  console.log("tokenB Address >> " + tokenB.address);
  console.log("tokenC Address >> " + tokenC.address);
  console.log("WETH Address >> " + WETH.address);

  // deploy uniswap stuff

  const UniswapV2Factory = new ethers.ContractFactory(
    UniswapV2FactoryJSON.abi,
    UniswapV2FactoryJSON.bytecode,
    owner
  );
  const uniFactory = await UniswapV2Factory.deploy(owner.address);
  await uniFactory.deployed();
  console.log("UniswapV2Factory Address >> " + uniFactory.address);

  const UNIFACTORY_INIT_CODE_HASH = ethers.utils.keccak256(
    UniswapV2Factory.bytecode
  );
  console.log("UNIFACTORY_INIT_CODE_HASH >> " + UNIFACTORY_INIT_CODE_HASH);

  async function createPair(token1: TestERC20, token2: TestERC20) {
    await uniFactory.createPair(token1.address, token2.address);
    const uniPairAddress: string = await uniFactory.getPair(
      token1.address,
      token2.address
    );
    const token1Symbol = await token1.symbol();
    const token2Symbol = await token2.symbol();
    console.log(token1Symbol + "/" + token2Symbol + " uniPairAddress >> "
      + uniPairAddress);
    return uniPairAddress;
  }

  await createPair(tokenA, tokenB);
  await createPair(tokenA, tokenC);
  await createPair(tokenB, tokenC);
  await createPair(tokenA, WETH);
  await createPair(tokenB, WETH);
  await createPair(tokenC, WETH);

  // deploy core stuff

  const GammaPoolFactory = await ethers.getContractFactory(
    GammaPoolFactoryJSON.abi,
    GammaPoolFactoryJSON.bytecode,
    owner
  );
  const gammaFactory = await GammaPoolFactory.deploy(owner.address);
  await gammaFactory.deployed();
  console.log("GammaPoolFactory Address >> " + gammaFactory.address);

  const CPMMProtocol = await ethers.getContractFactory(
    CPMMProtocolJSON.abi,
    CPMMProtocolJSON.bytecode,
    owner
  );
  const UNIPAIR_INIT_CODE_HASH = "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f";
  const protocol = await CPMMProtocol.deploy(
    gammaFactory.address,
    uniFactory.address,
    1,
    UNIPAIR_INIT_CODE_HASH,
    1000,
    997,
    10 ^ 16,
    8 * 10 ^ 17,
    4 * 10 ^ 16,
    75 * 10 ^ 16);
  await protocol.deployed();
  gammaFactory.addProtocol(protocol.address);
  console.log("CPMMProtocol Address >> " + protocol.address);

  const GAMMAPOOL_INIT_CODE_HASH = ethers.utils.keccak256(
    GammaPoolJSON.bytecode
  );
  console.log("GAMMAPOOL_INIT_CODE_HASH >> " + GAMMAPOOL_INIT_CODE_HASH);

  // deploy periphery stuff

  const PositionManager = await ethers.getContractFactory("PositionManager");
  const positionManager = await PositionManager.deploy(
    gammaFactory.address,
    WETH.address,
    GAMMAPOOL_INIT_CODE_HASH);
  await positionManager.deployed();
  console.log("PositionManager Address >> ", positionManager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

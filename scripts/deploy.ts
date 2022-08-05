import { ethers } from "hardhat";

async function main() {
  const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

  const Factory = await ethers.getContractFactory("TestGammaPoolFactory");
  const factory = await Factory.deploy(owner.address, addr1.address, addr2.address, addr3.address);

  const Erc20 = await ethers.getContractFactory("TestERC20");
  const erc20 = await Erc20.deploy("WETH", "WETH");

  const GammaPool = await ethers.getContractFactory("TestGammaPool");
  const COMPUTED_INIT_CODE_HASH = ethers.utils.keccak256(
    GammaPool.bytecode
  );

  const PositionManager = await ethers.getContractFactory("PositionManager");
  const positionManager = await PositionManager.deploy(factory.address, erc20.address, COMPUTED_INIT_CODE_HASH);
    
  await positionManager.deployed();

  console.log("PositionManager deployed to:", positionManager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

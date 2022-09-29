import { ethers } from "hardhat";

async function main() {
  const wethAddress = "<get this from deployPreCore deploy logs>";
  const GammaFactoryAddress = "<get this from v1core pre-strat deploy logs>";

  const PositionManager = await ethers.getContractFactory("PositionManager");
  const positionManager = await PositionManager.deploy(
    GammaFactoryAddress,
    wethAddress
  );
  await positionManager.deployed();
  console.log("PositionManager Address >> ", positionManager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

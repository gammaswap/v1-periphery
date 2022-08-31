import { ethers } from "hardhat";

async function main() {
  const metamaskAddress = "<address to sent to>"
  const [owner] = await ethers.getSigners();
  await owner.sendTransaction({
    to: metamaskAddress,
    value: ethers.utils.parseEther("100.0"), // Sends exactly 1.0 ether
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

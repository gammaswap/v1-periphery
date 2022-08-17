import { ethers } from "hardhat";

import {
  shouldBehaveLikeERC721,
  shouldBehaveLikeERC721Metadata
} from './ERC721.behavior';

describe("GammaPoolERC721", function () {
  let ERC721Mock: any;
  let name: any;
  let symbol: any;
  let tokenId: any;
  
  beforeEach(async function () {
    [this.owner, this.addr1, this.approved, this.operator, this.other] = await ethers.getSigners();

    this.name = 'Non Fungible Token';
    this.symbol = 'NFT';

    ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    this.token = await ERC721Mock.deploy(this.name, this.symbol);

    tokenId = 1;
    await this.token.mint(this.owner.address, tokenId);

    await this.token.deployed();
  })

  shouldBehaveLikeERC721("ERC721")
  shouldBehaveLikeERC721Metadata("ERC721")
})
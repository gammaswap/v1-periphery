import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { shouldSupportInterfaces } from "./SupportsInterface.behavior";
const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup.js")
// const Web3 = require('web3');

let Error: any;
let firstTokenId: any;
let secondTokenId: any;
let nonExistentTokenId: any;
let fourthTokenId: any;
let baseURI: any;
let RECEIVER_MAGIC_VALUE: any;
let ERC721ReceiverMock: any;
let signerMap: any;

Error = ['None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic'].reduce((acc, entry, idx) => Object.assign({ [entry]: idx }, acc), {});
firstTokenId = BigNumber.from('5042');
secondTokenId = BigNumber.from('79217');
nonExistentTokenId = BigNumber.from('13');
fourthTokenId = BigNumber.from(4);
baseURI = 'https://api.example.com/v1/';
RECEIVER_MAGIC_VALUE = '0x150b7a02';

console.log(firstTokenId);
console.log(secondTokenId);
console.log(nonExistentTokenId);
console.log(fourthTokenId);

export function shouldBehaveLikeERC721(errorPrefix: any) {
  shouldSupportInterfaces([
    'ERC165',
    'ERC721',
  ]);

  context('with minted tokens', function () {
    beforeEach(async function () {
      await this.token.mint(this.owner.address, firstTokenId);
      await this.token.mint(this.owner.address, secondTokenId);
      ERC721ReceiverMock = await ethers.getContractFactory("ERC721ReceiverMock");
      signerMap = new Map<any, any>([
        [this.approved.address, this.approved],
        [this.operator.address, this.operator],
        [this.other.address, this.other]
      ])
    });

    describe('balanceOf', function () {
      context('when the given address owns some tokens', function () {
        it('returns the amount of tokens owned by the given address', async function () {
          expect((await this.token.balanceOf(this.owner.address)).toNumber()).to.equal(3);
        });
      });

      context('when the given address does not own any tokens', function () {
        it('returns 0', async function () {
          expect((await this.token.balanceOf(this.addr1.address)).toNumber()).to.equal(0);
        });
      });

      context('when querying the zero address', function () {
        it('throws', async function () {
          await expect(this.token.balanceOf(ethers.constants.AddressZero)).to.be.revertedWith("ERC721: address zero is not a valid owner");
        });
      });
    });

    describe('ownerOf', function () {
      context('when the given token ID was tracked by this token', function () {
        const tokenId = firstTokenId;
        it('returns the owner of the given token ID', async function () {
          expect(await this.token.ownerOf(tokenId)).to.be.equal(this.owner.address);
        });
      });

      context('when the given token ID was not tracked by this token', function () {
        const tokenId = nonExistentTokenId;
        it('reverts', async function () {
          await expect(this.token.ownerOf(tokenId)).to.be.revertedWith('ERC721: invalid token ID');
        });
      });
    });

    describe('transfers', function () {
      const tokenId = firstTokenId;
      const data = '0x42';

      let receipt: any;

      beforeEach(async function () {
        await this.token.approve(this.approved.address, tokenId, { from: this.owner.address });
        await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address });
      });

      const transferWasSuccessful = function (tokenId: any) {
        it('transfers the ownership of the given token ID to the given address', async function () {
          expect(await this.token.ownerOf(tokenId)).to.be.equal(this.addr1.address);
        });

        it('emits a Transfer event', async function () {
          expect(receipt).to.emit(receipt, 'Transfer').withArgs({ from: this.owner.address, to: this.addr1.address, tokenId: tokenId });
        });

        it('clears the approval for the token ID', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(ethers.constants.AddressZero);
        });

        it('adjusts owners balances', async function () {
          expect((await this.token.balanceOf(this.owner.address)).toNumber()).to.equal(2);
        });

        it('adjusts owners tokens by index', async function () {
          if (!this.token.tokenOfOwnerByIndex) return;

          expect((await this.token.tokenOfOwnerByIndex(this.addr1.address, 0)).toNumber()).to.equal(tokenId);

          expect((await this.token.tokenOfOwnerByIndex(this.owner.address, 0)).toNumber()).to.not.equal(tokenId);
        });
      };

      const shouldTransferTokensByUsers = function (transferFunction: any) {
        context('when called by the owner', function () {
          beforeEach(async function () {
            (receipt = await transferFunction.call(this, this.owner.address, this.addr1.address, tokenId, { from: this.owner.address }));
          });
          transferWasSuccessful(tokenId);
        });

        context('when called by the approved individual', function () {
          beforeEach(async function () {
            (receipt = await transferFunction.call(this, this.owner.address, this.addr1.address, tokenId, { from: this.approved.address }));
          });
          transferWasSuccessful(tokenId);
        });

        context('when called by the operator', function () {
          beforeEach(async function () {
            (receipt = await transferFunction.call(this, this.owner.address, this.addr1.address, tokenId, { from: this.operator.address }));
          });
          transferWasSuccessful(tokenId);
        });

        context('when called by the owner without an approved user', function () {
          beforeEach(async function () {
            await this.token.approve(ethers.constants.AddressZero, tokenId, { from: this.owner.addrwess });
            (receipt = await transferFunction.call(this, this.owner.address, this.addr1.address, tokenId, { from: this.operator.address }));
          });
          transferWasSuccessful(tokenId);
        });

        context('when sent to the owner', function () {
          beforeEach(async function () {
            (receipt = await transferFunction.call(this, this.owner.address, this.owner.address, tokenId, { from: this.owner.address }));
          });

          it('keeps ownership of the token', async function () {
            expect(await this.token.ownerOf(tokenId)).to.be.equal(this.owner.address);
          });

          it('clears the approval for the token ID', async function () {
            expect(await this.token.getApproved(tokenId)).to.be.equal(ethers.constants.AddressZero);
          });

          it('emits only a transfer event', async function () {
            expect(receipt).to.emit(receipt, 'Transfer').withArgs({
              from: this.owner.address,
              to: this.owner.address,
              tokenId: tokenId,
            });
          });

          it('keeps the owner balance', async function () {
            expect(await this.token.balanceOf(this.owner.address)).to.equal('3');
          });

          it('keeps same tokens by index', async function () {
            if (!this.token.tokenOfOwnerByIndex) return;
            const tokensListed = await Promise.all(
              [0, 1].map(i => this.token.tokenOfOwnerByIndex(this.owner.address, i)),
            );
            expect(tokensListed.map(t => t.toNumber())).to.have.members(
              [firstTokenId.toNumber(), secondTokenId.toNumber()],
            );
          });
        });

        context('when the address of the previous owner is incorrect', function () {
          it('reverts', async function () {
            await expect(transferFunction.call(this, this.other.address, this.other.address, tokenId, { from: this.owner.address })).to.be.revertedWith("ERC721: transfer from incorrect owner");
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            await expect(transferFunction.call(this, this.owner.address, this.other.address, tokenId, { from: this.other.address })).to.be.revertedWith("ERC721: caller is not token owner nor approved");

          });
        });

        context('when the given token ID does not exist', function () {
          it('reverts', async function () {
            await expect(transferFunction.call(this, this.owner.address, this.other.address, nonExistentTokenId, { from: this.owner.address })).to.be.revertedWith("ERC721: invalid token ID");
          });
        });

        context('when the address to transfer the token to is the zero address', function () {
          it('reverts', async function () {
            await expect(transferFunction.call(this, this.owner.address, ethers.constants.AddressZero, tokenId, { from: this.owner.address })).to.be.revertedWith("ERC721: transfer to the zero address");
          });
        });
      };

      describe('via transferFrom', function () {
        shouldTransferTokensByUsers(function (this: any, from: any, to: any, tokenId: any, opts: any) {
          if (opts.from !== this.owner.address) {
            return this.token.connect(signerMap.get(opts.from)).transferFrom(from, to, tokenId, opts);
          }
          return this.token.transferFrom(from, to, tokenId, opts);
        });
      });

      describe('via safeTransferFrom', function () {
        const safeTransferFromWithData = function (this: any, from: any, to: any, tokenId: any, opts: any) {
          if (opts.from !== this.owner.address) {
            return this.token.connect(signerMap.get(opts.from)).functions['safeTransferFrom(address,address,uint256,bytes)'](from, to, tokenId, data, opts);
          }
          return this.token.functions['safeTransferFrom(address,address,uint256,bytes)'](from, to, tokenId, data, opts);
        };

        const safeTransferFromWithoutData = function (this: any, from: any, to: any, tokenId: any, opts: any) {
          if (opts.from !== this.owner.address) {
            return this.token.connect(signerMap.get(opts.from)).functions['safeTransferFrom(address,address,uint256)'](from, to, tokenId, opts);
          }
          return this.token.functions['safeTransferFrom(address,address,uint256)'](from, to, tokenId, opts);
        };

        const shouldTransferSafely = function (transferFun: any, data: any) {
          describe('to a user account', function () {
            shouldTransferTokensByUsers(transferFun);
          });

          describe('to a valid receiver contract', function () {
            beforeEach(async function () {
              this.receiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.None);
              this.toWhom = this.receiver.address;
            });

            shouldTransferTokensByUsers(transferFun);

            it('calls onERC721Received', async function () {
              const receipt = await (await transferFun.call(this, this.owner.address, this.receiver.address, tokenId, { from: this.owner.address })).wait();
              const receipt2 = await web3.eth.getTransactionReceipt(receipt.transactionHash);
              console.log("receipt >>");
              console.log(receipt2);

              await expectEvent.inTransaction(receipt.transactionHash, ERC721ReceiverMock, 'Received', {
                operator: this.owner.address,
                from: this.owner.address,
                tokenId: tokenId,
                data: data,
              });
            });

            it('calls onERC721Received from approved', async function () {
              const receipt = await (await transferFun.call(this, this.owner.address, this.receiver.address, tokenId, { from: this.approved.address })).wait();
              await expectEvent.inTransaction(receipt.transactionHash, ERC721ReceiverMock, 'Received', {
                operator: this.approved.address,
                from: this.owner.address,
                tokenId: tokenId,
                data: data,
              });
            });

            describe('with an invalid token id', function () {
              it('reverts', async function () {
                await expectRevert(
                  transferFun.call(
                    this,
                    this.owner.address,
                    this.receiver.address,
                    nonExistentTokenId,
                    { from: this.owner.address },
                  ),
                  'ERC721: invalid token ID',
                );
              });
            });
          });
        };

        describe('with data', function () {
          shouldTransferSafely(safeTransferFromWithData, data);
        });

        describe('without data', function () {
          shouldTransferSafely(safeTransferFromWithoutData, null);
        });

        describe('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await ERC721ReceiverMock.deploy('0x42000000', Error.None);

            await expectRevert(
              this.token.functions['safeTransferFrom(address,address,uint256)'](this.owner.address, invalidReceiver.address, tokenId, { from: this.owner.address }),
              'ERC721: transfer to non ERC721Receiver implementer',
            );
          });
        });

        describe('to a receiver contract that reverts with message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
            await expectRevert(
              this.token.functions['safeTransferFrom(address,address,uint256)'](this.owner.address, revertingReceiver.address, tokenId, { from: this.owner.address }),
              'ERC721ReceiverMock: reverting',
            );
          });
        });

        describe('to a receiver contract that reverts without message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
            await expectRevert(
              this.token.functions['safeTransferFrom(address,address,uint256)'](this.owner.address, revertingReceiver.address, tokenId, { from: this.owner.address }),
              'ERC721: transfer to non ERC721Receiver implementer',
            );
          });
        });

        describe('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.Panic);
            await expectRevert.unspecified(
              this.token.functions['safeTransferFrom(address,address,uint256)'](this.owner.address, revertingReceiver.address, tokenId, { from: this.owner.address }),
            );
          });
        });

        describe('to a contract that does not implement the required function', function () {
          it('reverts', async function () {
            const nonReceiver = this.token;
            await expectRevert(
              this.token.functions['safeTransferFrom(address,address,uint256)'](this.owner.address, nonReceiver.address, tokenId, { from: this.owner.address }),
              'ERC721: transfer to non ERC721Receiver implementer',
            );
          });
        });
      });
    });

    describe('safe mint', function () {
      const tokenId = fourthTokenId;
      const data = '0x42';

      describe('via safeMint', function () { // regular minting is tested in ERC721Mintable.test.js and others
        it('calls onERC721Received — with data', async function () {
          this.receiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.None);
          const receipt = await (await this.token.functions['safeMint(address,uint256,bytes)'](this.receiver.address, tokenId, data)).wait();

          await expectEvent.inTransaction(receipt.transactionHash, ERC721ReceiverMock, 'Received', {
            from: ethers.constants.AddressZero,
            tokenId: tokenId,
            data: data,
          });
        });

        it('calls onERC721Received — without data', async function () {
          this.receiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.None);
          const receipt = await (await this.token.functions['safeMint(address,uint256)'](this.receiver.address, tokenId)).wait();

          await expectEvent.inTransaction(receipt.transactionHash, ERC721ReceiverMock, 'Received', {
            from: ethers.constants.AddressZero,
            tokenId: tokenId,
          });
        });

        context('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await ERC721ReceiverMock.deploy('0x42000000', Error.None);
            await expectRevert(
              this.token.functions['safeMint(address,uint256)'](invalidReceiver.address, tokenId),
              'ERC721: transfer to non ERC721Receiver implementer',
            );
          });
        });

        context('to a receiver contract that reverts with message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
            await expectRevert(
              this.token.functions['safeMint(address,uint256)'](revertingReceiver.address, tokenId),
              'ERC721ReceiverMock: reverting',
            );
          });
        });

        context('to a receiver contract that reverts without message', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
            await expectRevert(
              this.token.functions['safeMint(address,uint256)'](revertingReceiver.address, tokenId),
              'ERC721: transfer to non ERC721Receiver implementer',
            );
          });
        });

        context('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.Panic);
            await expectRevert.unspecified(
              this.token.functions['safeMint(address,uint256)'](revertingReceiver.address, tokenId),
            );
          });
        });

        context('to a contract that does not implement the required function', function () {
          it('reverts', async function () {
            const nonReceiver = this.token;
            await expectRevert(
              this.token.functions['safeMint(address,uint256)'](nonReceiver.address, tokenId),
              'ERC721: transfer to non ERC721Receiver implementer',
            );
          });
        });
      });
    });

    describe('setApprovalForAll', function () {
      context('when the operator willing to approve is not the owner', function () {
        context('when there is no operator approval set by the sender', function () {
          it('approves the operator', async function () {
            await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address });

            expect(await this.token.isApprovedForAll(this.owner.address, this.operator.address)).to.equal(true);
          });

          it('emits an approval event', async function () {
            const receipt = await (await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address })).wait();
            expect(receipt).to.emit(receipt, 'ApprovalForAll').withArgs({
              owner: this.owner.address,
              operator: this.operator.address,
              approved: true,
            })
          });
        });

        context('when the operator was set as not approved', function () {
          beforeEach(async function () {
            await this.token.setApprovalForAll(this.operator.address, false, { from: this.owner.address });
          });

          it('approves the operator', async function () {
            await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address });

            expect(await this.token.isApprovedForAll(this.owner.address, this.operator.address)).to.equal(true);
          });

          it('emits an approval event', async function () {
            const receipt = await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address });

            expect(receipt).to.emit(receipt, 'ApprovalForAll').withArgs({
              owner: this.owner.address,
              operator: this.operator.address,
              approved: true,
            })
          });

          it('can unset the operator approval', async function () {
            await this.token.setApprovalForAll(this.operator.address, false, { from: this.owner.address });

            expect(await this.token.isApprovedForAll(this.owner.address, this.operator.address)).to.equal(false);
          });
        });

        context('when the operator was already approved', function () {
          beforeEach(async function () {
            await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address });
          });

          it('keeps the approval to the given address', async function () {
            await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address });

            expect(await this.token.isApprovedForAll(this.owner.address, this.operator.address)).to.equal(true);
          });

          it('emits an approval event', async function () {
            const receipt = await this.token.setApprovalForAll(this.operator.address, true, { from: this.owner.address });

            expect(receipt).to.emit(receipt, 'ApprovalForAll').withArgs({
              owner: this.owner.address,
              operator: this.operator.address,
              approved: true,
            })
          });
        });
      });

      context('when the operator is the owner', function () {
        it('reverts', async function () {
          await expectRevert(this.token.setApprovalForAll(this.owner.address, true, { from: this.owner.address }),
            'ERC721: approve to caller');
        });
      });
    });

    describe('getApproved', async function () {
      context('when token is not minted', async function () {
        it('reverts', async function () {
          await expectRevert(
            this.token.getApproved(nonExistentTokenId),
            'ERC721: invalid token ID',
          );
        });
      });

      context('when token has been minted ', async function () {
        it('should return the zero address', async function () {
          expect(await this.token.getApproved(firstTokenId)).to.be.equal(
            ethers.constants.AddressZero,
          );
        });

        context('when account has been approved', async function () {
          beforeEach(async function () {
            await this.token.approve(this.approved.address, firstTokenId, { from: this.owner.address });
          });

          it('returns approved account', async function () {
            expect(await this.token.getApproved(firstTokenId)).to.be.equal(this.approved.address);
          });
        });
      });
    });
  });

  describe('_mint(address, uint256)', function () {
    it('reverts with a null destination address', async function () {
      await expectRevert(
        this.token.mint(ethers.constants.AddressZero, firstTokenId), 'ERC721: mint to the zero address',
      );
    });

    context('with minted token', async function () {
      beforeEach(async function () {
        (this.receipt = await this.token.mint(this.owner.address, firstTokenId));
      });

      it('emits a Transfer event', function () {
        expect(this.receipt).to.emit(this.receipt, 'Transfer').withArgs({ from: ethers.constants.AddressZero, to: this.owner.address, tokenId: firstTokenId });
      });

      it('creates the token', async function () {
        expect((await this.token.balanceOf(this.owner.address)).toNumber()).to.equal('2');
        expect(await this.token.ownerOf(firstTokenId)).to.equal(this.owner.address);
      });

      it('reverts when adding a token id that already exists', async function () {
        await expectRevert(this.token.mint(this.owner.address, firstTokenId), 'ERC721: token already minted');
      });
    });
  });

  describe('_burn', function () {
    it('reverts when burning a non-existent token id', async function () {
      await expectRevert(
        this.token.burn(nonExistentTokenId), 'ERC721: invalid token ID',
      );
    });

    context('with minted tokens', function () {
      beforeEach(async function () {
        await this.token.mint(this.owner.address, firstTokenId);
        await this.token.mint(this.owner.address, secondTokenId);
      });

      context('with burnt token', function () {
        beforeEach(async function () {
          (this.receipt = await this.token.burn(firstTokenId));
        });

        it('emits a Transfer event', function () {
          expect(this.receipt).to.emit(this.receipt, 'Transfer').withArgs({ from: this.owner.address, to: ethers.constants.AddressZero, tokenId: firstTokenId });
        });

        it('deletes the token', async function () {
          expect((await this.token.balanceOf(this.owner.address)).toNumber()).to.equal(2);
          await expectRevert(
            this.token.ownerOf(firstTokenId), 'ERC721: invalid token ID',
          );
        });

        it('reverts when burning a token id that has been deleted', async function () {
          await expectRevert(
            this.token.burn(firstTokenId), 'ERC721: invalid token ID',
          );
        });
      });
    });
  });
}

export function shouldBehaveLikeERC721Metadata(errorPrefix: any) {
  shouldSupportInterfaces([
    'ERC721Metadata',
  ]);

  describe('metadata', function () {
    it('has a name', async function () {
      expect(await this.token.name()).to.be.equal(this.name);
    });

    it('has a symbol', async function () {
      expect(await this.token.symbol()).to.be.equal(this.symbol);
    });

    describe('token URI', function () {
      beforeEach(async function () {
        await this.token.mint(this.owner.address, firstTokenId);
      });

      it('return empty string by default', async function () {
        expect(await this.token.tokenURI(firstTokenId)).to.be.equal('');
      });

      it('reverts when queried for non existent token id', async function () {
        await expectRevert(
          this.token.tokenURI(nonExistentTokenId), 'ERC721: invalid token ID',
        );
      });

      describe('base URI', function () {
        beforeEach(function () {
          if (this.token.setBaseURI === undefined) {
            this.skip();
          }
        });

        it('base URI can be set', async function () {
          await this.token.setBaseURI(baseURI);
          expect(await this.token.baseURI()).to.equal(baseURI);
        });

        it('base URI is added as a prefix to the token URI', async function () {
          await this.token.setBaseURI(baseURI);
          expect(await this.token.tokenURI(firstTokenId)).to.be.equal(baseURI + firstTokenId.toString());
        });

        it('token URI can be changed by changing the base URI', async function () {
          await this.token.setBaseURI(baseURI);
          const newBaseURI = 'https://api.example.com/v2/';
          await this.token.setBaseURI(newBaseURI);
          expect(await this.token.tokenURI(firstTokenId)).to.be.equal(newBaseURI + firstTokenId.toString());
        });
      });
    });
  });
}
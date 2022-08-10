import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");

let Error: any;
let firstTokenId: any;
let secondTokenId: any;
let nonExistentTokenId: any;
let fourthTokenId: any;
let RECEIVER_MAGIC_VALUE: any;
let ERC721ReceiverMock: any;
let signerMap: any;

Error = ['None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic'].reduce((acc, entry, idx) => Object.assign({ [entry]: idx }, acc), {});
firstTokenId = BigNumber.from('5042');
secondTokenId = BigNumber.from('79217');
nonExistentTokenId = BigNumber.from('13');
fourthTokenId = BigNumber.from(4);
RECEIVER_MAGIC_VALUE = '0x150b7a02';

console.log(firstTokenId);
console.log(secondTokenId);
console.log(nonExistentTokenId);
console.log(fourthTokenId);

export function shouldBehaveLikeERC721(errorPrefix: any) {
    context('with minted tokens', function () {
        beforeEach(async function () {
            await this.token.mint(this.owner.address, firstTokenId);
            await this.token.mint(this.owner.address, secondTokenId);
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

            const transferWasSuccessful = function (tokenId:any) {
                it('transfers the ownership of the given token ID to the given address', async function () {
                    expect(await this.token.ownerOf(tokenId)).to.be.equal(this.addr1.address);
                });

                it('emits a Transfer event', async function () {
                    expect(receipt).to.emit(receipt,'Transfer').withArgs({ from: this.owner.address, to: this.addr1.address, tokenId: tokenId });
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
                        (receipt = await transferFunction.call(this, this.owner.address, this.addr1.address, tokenId , { from: this.approved.address }));
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
                        expect(receipt).to.emit(receipt,'Transfer').withArgs({
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
                            ERC721ReceiverMock = await ethers.getContractFactory("ERC721ReceiverMock");
                            this.receiver = await ERC721ReceiverMock.deploy(RECEIVER_MAGIC_VALUE, Error.None);
                            this.toWhom = this.receiver.address;
                        });

                        shouldTransferTokensByUsers(transferFun);

                        it('calls onERC721Received', async function () {
                            const receipt = await transferFun.call(this, this.owner.address, this.receiver.address, tokenId, { from: this.owner.address });

                            await expectEvent.inTransaction(receipt.hash, ERC721ReceiverMock, 'Received', {
                                operator: this.owner.address,
                                from: this.owner.address,
                                tokenId: tokenId,
                                data: data,
                            });
                        });

                        it('calls onERC721Received from approved', async function () {
                            const receipt = await transferFun.call(this, this.owner.address, this.receiver.address, tokenId, { from: this.approved.address });

                            await expectEvent.inTransaction(receipt.hash, ERC721ReceiverMock, 'Received', {
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

                // describe('to a receiver contract returning unexpected value', function () {
                //     it('reverts', async function () {
                //         const invalidReceiver = await ERC721ReceiverMock.new('0x42', Error.None);
                //         await expectRevert(
                //             this.token.safeTransferFrom(owner, invalidReceiver.address, tokenId, { from: owner }),
                //             'ERC721: transfer to non ERC721Receiver implementer',
                //         );
                //     });
                // });

                // describe('to a receiver contract that reverts with message', function () {
                //     it('reverts', async function () {
                //         const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
                //         await expectRevert(
                //             this.token.safeTransferFrom(owner, revertingReceiver.address, tokenId, { from: owner }),
                //             'ERC721ReceiverMock: reverting',
                //         );
                //     });
                // });

                // describe('to a receiver contract that reverts without message', function () {
                //     it('reverts', async function () {
                //         const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
                //         await expectRevert(
                //             this.token.safeTransferFrom(owner, revertingReceiver.address, tokenId, { from: owner }),
                //             'ERC721: transfer to non ERC721Receiver implementer',
                //         );
                //     });
                // });

                // describe('to a receiver contract that panics', function () {
                //     it('reverts', async function () {
                //         const revertingReceiver = await ERC721ReceiverMock.new(RECEIVER_MAGIC_VALUE, Error.Panic);
                //         await expectRevert.unspecified(
                //             this.token.safeTransferFrom(owner, revertingReceiver.address, tokenId, { from: owner }),
                //         );
                //     });
                // });

                // describe('to a contract that does not implement the required function', function () {
                //     it('reverts', async function () {
                //         const nonReceiver = this.token;
                //         await expectRevert(
                //             this.token.safeTransferFrom(owner, nonReceiver.address, tokenId, { from: owner }),
                //             'ERC721: transfer to non ERC721Receiver implementer',
                //         );
                //     });
                // });
            });
        });
    });
}
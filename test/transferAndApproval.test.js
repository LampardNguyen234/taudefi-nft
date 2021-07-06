var crypto = require("crypto");
const { assert } = require('chai')
const TauNFTFull = artifacts.require("./NFT/TauNFTFull.sol")

require('chai')
    .use(require('chai-as-promised'))
    .should()

const ZERO_ADDRESS = "003001";
const INVALID_NFT = "003002";
const NOT_OWNER_OR_OPERATOR = "003003";
const NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
const NOT_ABLE_TO_RECEIVE_NFT = "003005";
const NFT_ALREADY_EXISTS = "003006";
const NOT_OWNER = "003007";
const IS_OWNER = "003008";
const NFT_COUNT_MAX_EXCEEDED = "003009";

function shouldErrorContainMessage(error, message) {
    return error.message.search(`revert ${message}`) > 0
}

contract('TauNFTFull', (accounts) => {
    let contract

    let owner = accounts[0]
    let newOwner = accounts[1]
    let approvedUser = accounts[2]
    let zeroAddress = '0x0000000000000000000000000000000000000000'
    
    before (async() => {
        contract = await TauNFTFull.deployed()
    })

    describe("transferring and approval", async() => {
        it("transferFrom: owner should be able to transfer its token", async() => {
            //mint a token to test
            const _uri = crypto.randomBytes(30).toString('hex');
            const result = await contract.mint(owner, _uri)

            const event = result.logs[0].args
            let tokenId = event._tokenId

            //Transfer to another account
            await contract.transferFrom(owner, newOwner, tokenId)

            //Ownership of the token should be changed to newOwner
            tmpOwner = await contract.ownerOf(tokenId)
            assert.equal(tmpOwner, newOwner, "owner is invalid")

            //FAIL: owner cannot transfer this token since its ownership has been transferred to newOwner
            try {
                await contract.transferFrom(owner, newOwner, tokenId);
            } catch(error) {
                // Should throw a NOT_OWNER_APPROVED_OR_OPERATOR message
                assert.equal(shouldErrorContainMessage(error, NOT_OWNER_APPROVED_OR_OPERATOR), true)
            }
            

            //SUCCESS: newOwner should be able to transfer this token
            await contract.transferFrom(newOwner, owner, tokenId, {from: newOwner});
            
            //Ownership of this token now should be returned back to owner
            tmpOwner = await contract.ownerOf(tokenId)
            assert.equal(tmpOwner, owner, "owner is invalid")
        })

        it("transferFrom: should not be able to transfer a token to its owner", async() => {
            //mint a token to test
            const _uri = crypto.randomBytes(30).toString('hex');
            const result = await contract.mint(owner, _uri)

            const event = result.logs[0].args
            let tokenId = event._tokenId

            //Transfer to the owner
            try {
                await contract.transferFrom(owner, newOwner, tokenId)
            } catch(error) {
                // Should throw an IS_OWNER message
                assert.equal(shouldErrorContainMessage(error, IS_OWNER), true)
            }
        })

        it("safeTransferFrom", async() => {
            //mint a token to test
            const _uri = crypto.randomBytes(30).toString('hex');
            const result = await contract.mint(owner, _uri)

            const event = result.logs[0].args
            let tokenId = event._tokenId

            //Safely transfer to another account
            await contract.safeTransferFrom(owner, newOwner, tokenId)

            //Ownership of the token should be changed to newOwner
            tmpOwner = await contract.ownerOf(tokenId)
            assert.equal(tmpOwner, newOwner, "owner is invalid")

            //FAIL: owner cannot transfer this token
            await contract.safeTransferFrom(owner, newOwner, tokenId).should.be.rejected;

            //SUCCESS: newOwner should be able to transfer this token
            await contract.safeTransferFrom(newOwner, owner, tokenId, {from: newOwner});
            
            //Ownership of this token now should be returned back to owner
            tmpOwner = await contract.ownerOf(tokenId)
            assert.equal(tmpOwner, owner, "owner is invalid")

            //safeTransferFrom does the checks on the receiver being able to receive the NFTs
            //so this transferring will fail.
            await contract.safeTransferFrom(owner, zeroAddress, tokenId).should.be.rejected;
            
            //transferFrom doesn't check the receiver being able to receive the NFTs
            //so this transferring will be successful.
            await contract.transferFrom(owner, zeroAddress, tokenId);

            //Ownership of this token now should be changed to the zeroAddress
            try {
                await contract.ownerOf(tokenId)
            } catch (error) {
                // Should throw an INVALID_NFT message
                assert.equal(shouldErrorContainMessage(error, INVALID_NFT), true)
            }
        })

        it("approve", async() => {
            //mint a token to test
            const _uri = crypto.randomBytes(30).toString('hex');
            let result = await contract.mint(owner, _uri)

            let event = result.logs[0].args
            let tokenId = event._tokenId

            //Approve this token for the approvedUser
            result = await contract.approve(approvedUser, tokenId)
            event = result.logs[0].args
            
            assert.equal(event._owner, owner, "_owner is invalid")
            assert.equal(event._approved, approvedUser, "_approved is invalid")
            assert.equal(event._tokenId.eq(tokenId), true, "_tokenId is invalid")

            //approvedUser now can transfer this token to another account
            await contract.transferFrom(owner, newOwner, tokenId, {from: approvedUser})
            
            //Ownership of this token now should be changed to newOwner
            tmpOwner = await contract.ownerOf(tokenId)
            assert.equal(tmpOwner, newOwner, "owner is invalid")
        })

        it("setApprovalForAll", async() => {
            //mint 2 tokens to test
            let _uri = crypto.randomBytes(30).toString('hex');
            let result = await contract.mint(owner, _uri)
            let event = result.logs[0].args
            let tokenId1 = event._tokenId

            _uri = crypto.randomBytes(30).toString('hex');
            result = await contract.mint(owner, _uri)
            event = result.logs[0].args
            tokenId2 = event._tokenId

            //Allow approvedUser to spend owner's tokens
            result = await contract.setApprovalForAll(approvedUser, true)

            //approvedUser now can transfer these tokens to another account
            await contract.transferFrom(owner, newOwner, tokenId1, {from: approvedUser})
            await contract.transferFrom(owner, newOwner, tokenId2, {from: approvedUser})
            
            //Ownership of these tokens now should be changed to newOwner
            tmpOwner = await contract.ownerOf(tokenId1)
            assert.equal(tmpOwner, newOwner, "owner is invalid")
            tmpOwner = await contract.ownerOf(tokenId2)
            assert.equal(tmpOwner, newOwner, "owner is invalid")
        })

        it("revokeApproval", async() => {
            //mint 2 tokens to test
            let _uri = crypto.randomBytes(30).toString('hex');
            let result = await contract.mint(owner, _uri)
            let event = result.logs[0].args
            let tokenId1 = event._tokenId

            _uri = crypto.randomBytes(30).toString('hex');
            result = await contract.mint(owner, _uri)
            event = result.logs[0].args
            tokenId2 = event._tokenId

            //Allow approvedUser to spend owner's tokens
            await contract.setApprovalForAll(approvedUser, true)

            //approvedUser now can transfer these tokens to another account
            await contract.transferFrom(owner, newOwner, tokenId1, {from: approvedUser})

            //Ownership of tokenId1 now should be changed to newOwner
            tmpOwner = await contract.ownerOf(tokenId1)
            assert.equal(tmpOwner, newOwner, "owner is invalid")

            //revoke the approval permission
            await contract.setApprovalForAll(approvedUser, false)

            try {
                await contract.transferFrom(owner, newOwner, tokenId2, {from: approvedUser})
            } catch(error) {
                // Should throw a NOT_OWNER_APPROVED_OR_OPERATOR message
                assert.equal(shouldErrorContainMessage(error, NOT_OWNER_APPROVED_OR_OPERATOR), true)
            }
            
            //Ownership of tokenId2 now should stay unchanged
            tmpOwner = await contract.ownerOf(tokenId2)
            assert.equal(tmpOwner, owner, "owner is invalid")
        })
    })
})
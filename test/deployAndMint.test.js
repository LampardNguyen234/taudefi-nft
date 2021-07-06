var crypto = require("crypto");
const { assert } = require('chai')
const TauNFTFull = artifacts.require("./NFT/TauNFTFull.sol")

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('TauNFTFull', (accounts) => {
    let contract

    let vip0Account = accounts[0]
    let vip1Account = accounts[1]
    let vip2Account = accounts[2]
    
    before (async() => {
        contract = await TauNFTFull.deployed()
    })

    // console.log(`vip0Account: ${vip0Account}`)
    // console.log(`vip1Account: ${vip1Account}`)
    // console.log(`vip2Account: ${vip2Account}`)

    describe('deployment', async() => {
        it('deploys successfully', async()=> {
            const addr = await contract.address
            console.log(`contractAddress: ${addr}`)

            assert.notEqual(addr, "")
            assert.notEqual(addr, null)
            assert.notEqual(addr, undefined)
        })

        it('has a name', async()=> {
            const name = await contract.name()
            // console.log(`contractName: ${name}`)

            assert.equal(name, "TauNFT", "contract name invalid")
        })

        it('has a symbol', async()=> {
            const symbol = await contract.symbol()
            // console.log(`contractSymbol: ${symbol}`)

            assert.equal(symbol, "TauNFT", "contract symbol invalid")
        })
    })

    describe('minting', async() => {
        it("creates a new token", async() => {
            let uri = "aaaaababababababababababababababababa"
            const result = await contract.mint(vip0Account, uri)
        
            // console.log(result)

            //SUCCESS
            const event = result.logs[0].args
            assert.equal(event._tokenId, 1, "id is incorrect")
            assert.equal(event._from, "0x0000000000000000000000000000000000000000", '_from is incorrect')
            assert.equal(event._to, vip0Account, "_to is incorrect")
            
            //Check tokenURI
            tokenId = event._tokenId
            const tokenURI = await contract.tokenURI(tokenId)
            assert.equal(tokenURI, `ipfs://${uri}`, "tokenURI is invalid")

            //Check owner
            const owner = await contract.ownerOf(tokenId)
            assert.equal(owner, vip0Account, "own is invalid")

            //FAIL: cannot mint same color twice
            await contract.mint(vip0Account, uri).should.be.rejected;

            //FAIL: cannot mint same color twice, even for another account
            await contract.mint(vip1Account, uri).should.be.rejected;
        })

        it("is valid for VIP0 users", async() => {
            const count = await contract.balanceOf(vip0Account)
            console.log(`countNFT of vipOAccount: ${count}`)
            for (let i = 1; i <= 50 - count; i++) {
                let uri = crypto.randomBytes(20).toString('hex');
                
                const result = await contract.mint(vip0Account, uri)
                // console.log(result)

                const event = result.logs[0].args
                assert.equal(event._from, "0x0000000000000000000000000000000000000000", '_from is incorrect')
                assert.equal(event._to, vip0Account, "_to is incorrect")
                
                //Check tokenURI
                tokenId = event._tokenId
                const tokenURI = await contract.tokenURI(tokenId)
                assert.equal(tokenURI, `ipfs://${uri}`, "tokenURI is invalid")

                const balance = await contract.balanceOf(vip0Account)
                assert.equal(balance, parseInt(count) + parseInt(i), "balance is incorrect")

                if (i % 10 == 0) {
                    //console.log(`mint token ${parseInt(i) + parseInt(count)} successfully`)
                }
            }
            
            let uri = crypto.randomBytes(20).toString('hex');
            await contract.mint(vip0Account, uri).should.be.rejected;
        })

        it("is valid for VIP1 users", async(done) => {
            const count = await contract.balanceOf(vip1Account)
            console.log(`countNFT of vip1Account: ${count}`)
            for (let i = 1; i <= 200 - count; i++) {
                let uri = crypto.randomBytes(20).toString('hex');
                
                const result = await contract.mint(vip1Account, uri)
                // console.log(result)

                const event = result.logs[0].args
                assert.equal(event._from, "0x0000000000000000000000000000000000000000", '_from is incorrect')
                assert.equal(event._to, vip1Account, "_to is incorrect")
                
                //Check tokenURI
                tokenId = event._tokenId
                const tokenURI = await contract.tokenURI(tokenId)
                assert.equal(tokenURI, `ipfs://${uri}`, "tokenURI is invalid")

                const balance = await contract.balanceOf(vip1Account)
                assert.equal(balance, parseInt(count) + parseInt(i), "balance is incorrect")

                if (i % 10 == 0) {
                    //console.log(`mint token ${parseInt(i) + parseInt(count)} successfully`)
                }
            }
            
            let uri = crypto.randomBytes(20).toString('hex');
            await contract.mint(vip1Account, uri).should.be.rejected;

            done()
        }).timeout(1000000)

        it("is valid for VIP2 users", async(done) => {
            const count = await contract.balanceOf(vip2Account)
            // console.log(`countNFT of vip2Account: ${count}`)
            for (let i = 1; i <= 201 - count; i++) {
                let uri = crypto.randomBytes(20).toString('hex');
                
                const result = await contract.mint(vip2Account, uri)
                // console.log(result)

                const event = result.logs[0].args
                assert.equal(event._from, "0x0000000000000000000000000000000000000000", '_from is incorrect')
                assert.equal(event._to, vip2Account, "_to is incorrect")
                
                //Check tokenURI
                tokenId = event._tokenId
                const tokenURI = await contract.tokenURI(tokenId)
                assert.equal(tokenURI, `ipfs://${uri}`, "tokenURI is invalid")

                const balance = await contract.balanceOf(vip2Account)
                assert.equal(balance, parseInt(count) + parseInt(i), "balance is incorrect")
                
                if (i % 10 == 0) {
                    //console.log(`mint token ${parseInt(i) + parseInt(count)} successfully`)
                }
            }

            done()
        }).timeout(1000000)
    })
})
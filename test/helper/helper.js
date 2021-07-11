async function mintToken(contract, owner, uri, license, expiryDate) {
    if (owner === '0x0000000000000000000000000000000000000000') {
        return await contract.mint(owner, uri, license, expiryDate)
    }
    return await contract.mint(owner, uri, license, expiryDate, {from: owner})
}

async function mintRandomToken(contract, owner, license) {
    let uri = crypto.randomBytes(32).toString('hex');
    let expiryDate = "10000000000000000000";
    if (owner === '0x0000000000000000000000000000000000000000') {
        return await contract.mint(owner, uri, license, expiryDate)
    }
    return await contract.mint(owner, uri, license, expiryDate, {from: owner})
}

async function wait(timeOut) {
    return new Promise(resolve => {
        setTimeout(resolve, timeOut);
    });
}

module.exports = {mintToken, mintRandomToken, wait}
const TaureumKYCMock = artifacts.require("./TaureumKYCMock.sol")

async function addVerifiedUser(verifiedUser) {
    let contract = await TaureumKYCMock.deployed()
    try
    {
        await contract.addVerifier(verifiedUser);
        // console.log(`addVerifier ${verifiedUser} successfully!!`)
    } catch (error) {
        throw(error)
    }
}

module.exports = {addVerifiedUser};

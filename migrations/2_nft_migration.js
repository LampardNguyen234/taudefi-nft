const TaureumKYCMock = artifacts.require("TaureumKYCMock");
const TaureumNFT = artifacts.require("TaureumNFT");

module.exports = async function (deployer) {
    let kycContractAddress

    await deployer.deploy(TaureumKYCMock)
    kycContract = await TaureumKYCMock.deployed()
    kycContractAddress = kycContract.address
    console.log("KYC contract deployed at address", kycContractAddress)

    await deployer.deploy(TaureumNFT, kycContractAddress);
    mainContract = await TaureumNFT.deployed();
    mainContractAddress = await mainContract.address
    console.log("Main contract deployed at address", mainContractAddress)
};
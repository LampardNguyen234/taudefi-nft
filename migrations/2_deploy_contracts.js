const TauNFTFull = artifacts.require("TauNFTFull");

module.exports = function (deployer) {
  deployer.deploy(TauNFTFull, "TauNFT", "TauNFT");
};

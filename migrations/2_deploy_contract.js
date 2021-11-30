const Contract = artifacts.require("kycContract.sol");

module.exports = function (deployer) {
  deployer.deploy(Contract);
};

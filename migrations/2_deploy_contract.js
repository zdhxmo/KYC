const Contract = artifacts.require("KYC_Contract.sol");

module.exports = function (deployer) {
  deployer.deploy(Contract);
};

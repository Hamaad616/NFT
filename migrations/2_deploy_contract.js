const NewToken = artifacts.require("NewToken.sol");

module.exports = function (deployer) {
  deployer.deploy(NewToken);
};

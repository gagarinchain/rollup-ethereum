var Rollups = artifacts.require("./Rollups.sol");

var PbRuntime = artifacts.require("_pb");
var pb_Rollup = artifacts.require("pb_Rollup");

// Accounts
accounts = web3.eth.accounts;

module.exports = function(deployer) {
    deployer.deploy(PbRuntime).then(function () {
        return deployer.deploy(PbRuntime);
    }).then(function () {
        pb_Rollup.link(PbRuntime);
        return deployer.deploy(pb_Rollup);
    }).then(function () {
        Rollups.link(pb_Rollup);
        return deployer.deploy(Rollups, [
            "0x728d9Dd511dc5725829C578D9beA083cDfC2ceDD",
            "0x16C997a49A61EeA424f9bCc0c85543cC6d71799f",
            "0x094194624493E84485a41a8F7844a73eD36dA7F4"]);
    })//*/;
};

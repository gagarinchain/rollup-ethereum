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
            "0x8185726EDb012D1A0A53f50c218B1Ed1bBaD7fE3",
            "0x4026a2512f2b37107a547fc98578f37357c4bd1c"]);
    })//*/;
};

var Rollups = artifacts.require("./Rollups.sol");

var DataTypes = artifacts.require("./DataTypes.sol");
var Gateway = artifacts.require("./Gateway.sol");
var TestERC20 = artifacts.require("./TestERC20.sol");
var SafeERC20 = artifacts.require("@openzeppelin/contracts/token/ERC20/SafeERC20.sol");
var SafeMath = artifacts.require("@openzeppelin/contracts/math/SafeMath.sol");

// Accounts
accounts = web3.eth.accounts;

module.exports = async function (deployer) {
    await deployer.deploy(SafeERC20);
    const safeERC20 = await SafeERC20.deployed();

    await deployer.deploy(SafeMath);
    const safeMath = await SafeMath.deployed();

    await deployer.deploy(DataTypes);
    const dataTypes = await DataTypes.deployed();
    await deployer.link(SafeMath, SafeERC20);;
    await deployer.link(SafeERC20, Gateway);;

    await deployer.deploy(TestERC20, [
        "0x5Aa9628B647E8BC1Cb17346A2b0C4f3c12Ee81Fd",
        "0xEE4a73cf0CBE6e850E7Be821AEB3A7382D2c02C5",
        "0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503"
    ]);
    const testERC20 = await TestERC20.deployed();

    await deployer.deploy(Gateway, testERC20.address);
    const gateway = await Gateway.deployed();
    await deployer.link(DataTypes, Rollups);
    await deployer.link(SafeMath, Rollups);
    await deployer.deploy(Rollups, [
            "0x5Aa9628B647E8BC1Cb17346A2b0C4f3c12Ee81Fd",
            "0xEE4a73cf0CBE6e850E7Be821AEB3A7382D2c02C5",
            "0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503"], gateway.address);

    gateway.setRollupManager(Rollups.address)
    gateway.register("0x5Aa9628B647E8BC1Cb17346A2b0C4f3c12Ee81Fd", "0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950")

};


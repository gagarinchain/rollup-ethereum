const { accounts, contract } = require('@openzeppelin/test-environment');
const {
    BN,           // Big Number support
    constants,    // Common constants, like the zero address and largest integers
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time,
} = require('@openzeppelin/test-helpers');

const [ admin, purchaser, manager ] = accounts;

const { expect } = require('chai');

const Gateway = contract.fromArtifact('Gateway');
const TestERC20 = contract.fromArtifact('TestERC20');


describe('Gateway tests', () => {

    it('Cancel deposit', async () => {
        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await instance.register("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: admin });
        let before = await token.balanceOf(admin, { from: admin });
        await token.increaseAllowance(instance.address, 100, { from: admin });
        await instance.lockTokens(100, { from: admin });
        let after = await token.balanceOf(admin, { from: admin });
        time.advanceBlockTo(time.latestBlock() + 50);

        expect(before - after, 0)
    });

    it('Cancel not deposited', async () => {
        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await instance.register("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: admin });
        expectRevert(instance.cancelDeposit({ from: admin }), "!noDepositToCancel -- Reason given: !noDepositToCancel.");
    });

    it('Cancel not expired', async () => {
        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await instance.register("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: admin });
        await token.increaseAllowance(instance.address, 100, { from: admin });
        await instance.lockTokens(100, { from: admin });
        time.advanceBlockTo(time.latestBlock() + 20);
        expectRevert(instance.cancelDeposit({ from: admin }), "!depositIsNotExpiredYet -- Reason given: !depositIsNotExpiredYet.");
    });

    it('Double registration with same eth address', async () => {

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await instance.register("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: admin });
        expectRevert(instance.register("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00", { from: admin }), "!doubleRegistrationEth");
    });

    it('Double registration with same gagarin address', async () => {

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await instance.register("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: admin });
        expectRevert(instance.register("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: purchaser }), "doubleRegistrationGagarin -- Reason given: !doubleRegistrationGagarin.");
    });

    it('Deposit registered', async () => {

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await token.increaseAllowance(instance.address, 100, { from: admin });
        let before = await token.balanceOf(admin, { from: admin });
        await instance.register("0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503", { from: admin });
        await instance.lockTokens(100, { from: admin });
        let after = await token.balanceOf(admin, { from: admin });

        expect(before - after).to.equal(100);
    });

    it('Deposit not registered', async () => {

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await token.increaseAllowance(instance.address, 100, { from: admin });
        let before = await token.balanceOf(admin, { from: admin });
        expectRevert(instance.lockTokens(100, { from: admin }), "!registered");
        let after = await token.balanceOf(admin, { from: admin });

        expect(before - after).to.equal(0);
    });

    it('Confirm deposit not manager', async () => {

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await token.increaseAllowance(instance.address, 100, { from: admin });
        let before = await token.balanceOf(admin, { from: admin });
        await instance.register("0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503", { from: admin });
        await instance.lockTokens(100, { from: admin });
        let after = await token.balanceOf(admin, { from: admin });

        expect(before - after).to.equal(100);

        await instance.setRollupManager(manager, { from: admin });
        expectRevert(instance.confirmDeposit("0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503", { from: purchaser }),
            "!rollupsManager -- Reason given: !rollupsManager.")
    });

    it('Confirm deposit by manager with wrong gagarin address', async () => {

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await token.increaseAllowance(instance.address, 200, { from: admin });
        let before = await token.balanceOf(admin, { from: admin });
        await instance.register("0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503", { from: admin });
        await instance.lockTokens(100, { from: admin });

        await instance.setRollupManager(manager, { from: admin });
        await instance.confirmDeposit("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: manager });

        let confirmed = await token.balanceOf(admin, { from: admin });
        expect(before - confirmed).to.equal(100);

        expectRevert(instance.lockTokens(100, { from: admin }), "!pendingNotExpired -- Reason given: !pendingNotExpired.")
    });

    it('Confirm deposit by manager', async () => {

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let instance = await Gateway.new(token.address, { from: admin });
        await token.increaseAllowance(instance.address, 200, { from: admin });
        let before = await token.balanceOf(admin, { from: admin });
        await instance.register("0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503", { from: admin });
        await instance.lockTokens(100, { from: admin });

        await instance.setRollupManager(manager, { from: admin });
        await instance.confirmDeposit("0x3d7D7aF30Df4dd980D7b4454774C78719ca2c503", { from: manager });

        let confirmed = await token.balanceOf(admin, { from: admin });
        expect(before - confirmed).to.equal(100);

        await instance.lockTokens(100, { from: admin });
        let afterConfirmed = await token.balanceOf(admin, { from: admin });

        expect(confirmed - afterConfirmed).to.equal(100);
    });

});
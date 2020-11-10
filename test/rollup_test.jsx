const { accounts, contract } = require('@openzeppelin/test-environment');
const {
    BN,           // Big Number support
    constants,    // Common constants, like the zero address and largest integers
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time,
} = require('@openzeppelin/test-helpers');

const [ admin, purchaser, manager, acc0, acc1, acc2, acc3 ] = accounts;

const { expect } = require('chai');

const SafeMath = contract.fromArtifact('SafeMath');
const Rollups = contract.fromArtifact('Rollups');
const DT = contract.fromArtifact('DataTypes');
const Gateway = contract.fromArtifact('Gateway');
const TestERC20 = contract.fromArtifact('TestERC20');

describe('Rollups simple test', () => {
    it('Parse rollup test', async () => {
        let dt = await DT.new({ from: admin });

        let r  = Buffer.from(rollup.substring(2), 'hex');
        let parsed = await dt.parseRollup.call(r);

        console.log(parsed);

        expect(parsed.accounts[0]).to.equals("0x57c85258f66A7b61D54b484a129E06013250C6c1");
        expect(parsed.accounts[1]).to.equals("0x722eEb8B3ec30d5D63fc8f301B151d3a341360c6");
        expect(parsed.accounts[2]).to.equals("0x70979A317eA1b136934CEfCFC889c7086ADDFAE2");

        expect(parsed.transactions[0].from).to.equals("1");
        expect(parsed.transactions[0].to).to.equals("3");
        expect(parsed.transactions[0].value).to.equals("10");

        expect(parsed.transactions[1].from).to.equals("4");
        expect(parsed.transactions[1].to).to.equals("5");
        expect(parsed.transactions[1].value).to.equals("33");

    });

    it('Parse header', async () => {
        let dt = await DT.new({ from: admin });

        let r  = Buffer.from(header.substring(2), 'hex');
        let parsed = await dt.parseBlockHeader.call(r);

        console.log(parsed);

        expect(parsed.hash).to.equals("0xe46b55fcd8a51cfe1cd1de8eaaf6e5a9993d1e2e72b74f657f13638e3937f08a");
        expect(parsed.parentHash).to.equals("0xa55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8");
        expect(parsed.qcHash).to.equals("0xc6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5b");
        expect(parsed.dataHash).to.equals("0x95d28850dc5176083450019b81a35958316e2e0aa9731c1fc049969383072c4a");
        expect(parsed.txHash).to.equals("0x9e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae31");
        expect(parsed.stateHash).to.equals("0x7affdde4474baacd73cbd3437d946c841a0686171aff2bbf4b29a410b283e5e8");
        expect(parsed.height).to.equals("15");
        expect(parsed.timestamp).to.equals("1600717944");

    });

    it('Process rollup lock completed', async () => {
        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let dt = await DT.new({ from: admin });
        let gateway = await Gateway.new(token.address, { from: admin });
        await Rollups.detectNetwork();
        await Rollups.link("DataTypes", dt.address);
        let rollups = await Rollups.new([ admin, purchaser, manager], gateway.address, { from: admin });

        await token.increaseAllowance(gateway.address, 200, { from: admin });
        await gateway.register(admin, "0x57c85258f66A7b61D54b484a129E06013250C6c1", { from: admin });
        await gateway.lockTokens(100, { from: admin });
        await gateway.setRollupManager(rollups.address, { from: admin });

        let receipt = await rollups.addBlock(header2, rollup2, [], { from: admin });
        expectEvent(receipt, "TopHeightUpdate", {height:"1"});

        let balance = await rollups.getBalance("0x57c85258f66A7b61D54b484a129E06013250C6c1");

        await gateway.lockTokens(100, { from: admin }); //if no error it means we removed pending
        expect(balance.toNumber()).to.equals(10)

    });

    it('Process rollup unlock completed', async () => {
        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let dt = await DT.new({ from: admin });
        let gateway = await Gateway.new(token.address, { from: admin });
        await Rollups.detectNetwork();
        await Rollups.link("DataTypes", dt.address);
        let rollups = await Rollups.new([ admin, purchaser, manager], gateway.address, { from: admin });

        await token.increaseAllowance(gateway.address, 200, { from: admin });
        await gateway.register(admin, "0x57c85258f66A7b61D54b484a129E06013250C6c1", { from: admin });
        await gateway.lockTokens(100, { from: admin });
        await gateway.setRollupManager(rollups.address, { from: admin });

        let receipt1 = await rollups.addBlock(header2, rollup2, [], { from: admin });
        expectEvent(receipt1, "TopHeightUpdate", {height:"1"});

        let balance1 = await rollups.getBalance("0x57c85258f66A7b61D54b484a129E06013250C6c1");
        expect(balance1.toNumber()).to.equals(10); //added 10 tokens to account

        let receipt2 = await rollups.addBlock(header3, rollup3, [], { from: admin });
        expectEvent(receipt2, "TopHeightUpdate", {height:"2"});

        let balance2 = await rollups.getBalance("0x57c85258f66A7b61D54b484a129E06013250C6c1");
        expect(balance2.toNumber()).to.equals(0) //redeem 10 tokens to account

    });
    it('Process rollup unlock with not finished pending', async () => {
        let math = await SafeMath.new({ from: admin });
        await TestERC20.detectNetwork();
        await TestERC20.link("SafeMath", math.address);

        let token = await TestERC20.new([admin, purchaser], { from: admin });
        let dt = await DT.new({ from: admin });
        let gateway = await Gateway.new(token.address, { from: admin });
        await Rollups.detectNetwork();
        await Rollups.link("DataTypes", dt.address);
        await Rollups.link("SafeMath", math.address);
        let rollups = await Rollups.new([ admin, purchaser, manager], gateway.address, { from: admin });

        await token.increaseAllowance(gateway.address, 200, { from: admin });
        await gateway.register(admin, "0x57c85258f66A7b61D54b484a129E06013250C6c1", { from: admin });
        await gateway.lockTokens(100, { from: admin });
        await gateway.setRollupManager(rollups.address, { from: admin });

        rollups.addBlock(header3_1, rollup3, [], { from: admin });

         let balance2 = await token.balanceOf("0x57c85258f66A7b61D54b484a129E06013250C6c1");
         expect(balance2.toNumber()).to.equals(0) //no tokens at balance

    });

    it('Process series of rollups', async () => {
        let token = await TestERC20.new([acc0, acc2], { from: admin });
        let dt = await DT.new({ from: admin });
        let gateway = await Gateway.new(token.address, { from: admin });
        await Rollups.detectNetwork();
        await Rollups.link("DataTypes", dt.address);
        let rollups = await Rollups.new([ admin, purchaser, manager], gateway.address, { from: admin });

        await token.increaseAllowance(gateway.address, 100, { from: acc0 });
        await token.increaseAllowance(gateway.address, 200, { from: acc2 });
        await gateway.register(acc0, "0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: admin });
        await gateway.register(acc1, "0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00", { from: admin });
        await gateway.register(acc2, "0x41E46d84c206007982F93C0874152B8cF6127985", { from: admin });
        await gateway.register(acc3, "0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2", { from: admin });

        await gateway.lockTokens(100, { from: acc0 });
        await gateway.lockTokens(200, { from: acc2 });
        await gateway.setRollupManager(rollups.address, { from: admin });

        rollups.addBlock(header4_1, rollup4_1, [], { from: admin });

        let balance0 = await rollups.getBalance("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950");
        expect(balance0.toNumber()).to.equals(100 - 13 + 8 + 16); //no tokens at balance
        let balance1 = await rollups.getBalance("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00");
        expect(balance1.toNumber()).to.equals(13 - 1 - 4); //no tokens at balance
        let balance2 = await rollups.getBalance("0x41E46d84c206007982F93C0874152B8cF6127985");
        expect(balance2.toNumber()).to.equals(200 + 1 - 8 - 16); //no tokens at balance
        let balance3 = await rollups.getBalance("0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2");
        expect(balance3.toNumber()).to.equals(4) //no tokens at balance

        rollups.addBlock(header4_3, rollup4_3, [], { from: admin });

        let balance0_1 = await rollups.getBalance("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950");
        expect(balance0_1.toNumber()).to.equals(100 - 13 + 8 + 16 + 1 + 4 - 13); //no tokens at balance
        let balance1_1 = await rollups.getBalance("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00");
        expect(balance1_1.toNumber()).to.equals(13 - 1 - 4 - 1 - 4 + 13); //no tokens at balance
        let balance2_1 = await rollups.getBalance("0x41E46d84c206007982F93C0874152B8cF6127985");
        expect(balance2_1.toNumber()).to.equals(200 + 1 - 8 - 16); //no tokens at balance
        let balance3_1 = await rollups.getBalance("0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2");
        expect(balance3_1.toNumber()).to.equals(4) //no tokens at balance

        rollups.addBlock(header4_4, rollup4_4, [], { from: admin });

        let balance0_2 = await rollups.getBalance("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950");
        expect(balance0_2.toNumber()).to.equals(100 - 13 + 8 + 16 + 1 + 4 - 13 - 5 - 4 + 13); //no tokens at balance
        let balance1_2 = await rollups.getBalance("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00");
        expect(balance1_2.toNumber()).to.equals(13 - 1 - 4 - 1 - 4 + 13 + 5 - 8 + 16); //no tokens at balance
        let balance2_2 =    await rollups.getBalance("0x41E46d84c206007982F93C0874152B8cF6127985");
        expect(balance2_2.toNumber()).to.equals(200 + 1 - 8 - 16 - 13 + 8 - 16); //no tokens at balance
        let balance3_2 = await rollups.getBalance("0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2");
        expect(balance3_2.toNumber()).to.equals(4 + 4) //no tokens at balance

    });
    it('Process series of rollups with wrong order', async () => {
        let token = await TestERC20.new([acc0, acc2], { from: admin });
        let dt = await DT.new({ from: admin });
        let gateway = await Gateway.new(token.address, { from: admin });
        await Rollups.detectNetwork();
        await Rollups.link("DataTypes", dt.address);
        let rollups = await Rollups.new([ admin, purchaser, manager], gateway.address, { from: admin });

        await token.increaseAllowance(gateway.address, 100, { from: acc0 });
        await token.increaseAllowance(gateway.address, 200, { from: acc2 });
        await gateway.register(acc0, "0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950", { from: admin });
        await gateway.register(acc1, "0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00", { from: admin });
        await gateway.register(acc2, "0x41E46d84c206007982F93C0874152B8cF6127985", { from: admin });
        await gateway.register(acc3, "0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2", { from: admin });

        await gateway.lockTokens(100, { from: acc0 });
        await gateway.lockTokens(200, { from: acc2 });
        await gateway.setRollupManager(rollups.address, { from: admin });

        rollups.addBlock(header4_2, rollup4_2, [], { from: admin });

        let balance0 = await rollups.getBalance("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950");
        expect(balance0.toNumber()).to.equals(100 - 13 + 8 + 16); //no tokens at balance
        let balance1 = await rollups.getBalance("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00");
        expect(balance1.toNumber()).to.equals(13 - 1 - 4); //no tokens at balance
        let balance2 = await rollups.getBalance("0x41E46d84c206007982F93C0874152B8cF6127985");
        expect(balance2.toNumber()).to.equals(200 + 1 - 8 - 16); //no tokens at balance
        let balance3 = await rollups.getBalance("0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2");
        expect(balance3.toNumber()).to.equals(4) //no tokens at balance
    });

});

/**
 * (common.Address) (len=20 cap=20) 0x57c85258f66A7b61D54b484a129E06013250C6c1
 * (common.Address) (len=20 cap=20) 0x722eEb8B3ec30d5D63fc8f301B151d3a341360c6
 * (common.Address) (len=20 cap=20) 0x70979A317eA1b136934CEfCFC889c7086ADDFAE2
 */
let rollup = "0x080000004400000057c85258f66a7b61d54b484a129e06013250c6c1722eeb8b3ec30d5d63fc8f301b151d3a341360c670979a317ea1b136934cefcfc889c7086addfae201000000030000000a0000000000000004000000050000002100000000000000";
let header = "0x0f000000e46b55fcd8a51cfe1cd1de8eaaf6e5a9993d1e2e72b74f657f13638e3937f08a9e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae317affdde4474baacd73cbd3437d946c841a0686171aff2bbf4b29a410b283e5e895d28850dc5176083450019b81a35958316e2e0aa9731c1fc049969383072c4ac6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b87804695f00000000";

/**
 * (common.Address) (len=20 cap=20) 0x57c85258f66A7b61D54b484a129E06013250C6c1
 * 			{
 *				From:  -1,
 *				To:    0,
 *				Value: 10,
 *			}
 */
let rollup2 = "0x080000001c00000057c85258f66a7b61d54b484a129e06013250c6c1ffffffff000000000a00000000000000";
let header2 = "0x01000000fc65d25d35594faab6cdafc70ce543de55ff71ca0662b5d98d905f96e70bb9469e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae310000000000000000000000000000000000000000000000000000000000000000a82e3d7e96d07730f747b7bd4c13b7bba33b9f91a1db6dc99ec142941e6f9a3fc6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8903d785f00000000";


/**
 * (common.Address) (len=20 cap=20) 0x57c85258f66A7b61D54b484a129E06013250C6c1
 * 			{
 *				From:  0,
 *				To:    -1,
 *				Value: 10,
 *			}
 */
let rollup3 = "0x080000001c00000057c85258f66a7b61d54b484a129e06013250c6c100000000ffffffff0a00000000000000";
let header3 = "0x02000000553f0ca7fb097cef77c10a060808b9e9694c6f7d09bba6817d85f0856a2003139e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae310000000000000000000000000000000000000000000000000000000000000000958fba74f5f3a14c58f9ebeb9b388f8cf63e90246b02912e5e7bfaf46c988621c6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8903d785f00000000";
let header3_1 = "0x010000001e4a099d5852d37ecfdf968e89d5d1d946b994354f22b9463d2bd3c277117db09e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae310000000000000000000000000000000000000000000000000000000000000000958fba74f5f3a14c58f9ebeb9b388f8cf63e90246b02912e5e7bfaf46c988621c6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8903d785f00000000";



/**
 * a0 := c.HexToAddress("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950")
 a1 := c.HexToAddress("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00")
 a2 := c.HexToAddress("0x41E46d84c206007982F93C0874152B8cF6127985")
 a3 := c.HexToAddress("0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2")
 rollup := Rollup{
		Accounts:     [][20]byte{a0, a1, a2, a3},
		Transactions: []*Transaction{
			{
				From:  -1,
				To:    0,
				Value: 100,
			},{
				From:  -1,
				To:    2,
				Value: 200,
			},
			{
				From:  0,
				To:    1,
				Value: 13,
			},{
				From:  1,
				To:    2,
				Value: 1,
			},{
				From:  1,
				To:    3,
				Value: 4,
			},{
				From:  2,
				To:    0,
				Value: 8,
			},{
				From:  2,
				To:    0,
				Value: 16,
			},
		},
	}
 */
let rollup4_1 = "0x0800000058000000dd9811cfc24ab8d56036a8eca90c7b8c75e35950f3aa514423ae2c6f66497d69f2fc899f0ad25b0041e46d84c206007982f93c0874152b8cf612798595ac9774cf32adb66f76726502fc0c223bce13e2ffffffff000000006400000000000000ffffffff02000000c80000000000000000000000010000000d0000000000000001000000020000000100000000000000010000000300000004000000000000000200000000000000080000000000000002000000000000001000000000000000";
let header4_1 = "0x010000008ba5c4efc1303fba9509d44ce7cc54045b8476cd94c200a520f903d06e008ba89e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae3100000000000000000000000000000000000000000000000000000000000000001b99753023f81ffb27f4cbe3f2daff623e5a66f380d63db7cfee16f21141f0a0c6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8903d785f00000000";




/**
 * 	a0 := c.HexToAddress("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950")
 a1 := c.HexToAddress("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00")
 a2 := c.HexToAddress("0x41E46d84c206007982F93C0874152B8cF6127985")
 a3 := c.HexToAddress("0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2")
 rollup := Rollup{
		Accounts:     [][20]byte{a0, a1, a2, a3},
		Transactions: []*Transaction{
			{
				From:  -1,
				To:    0,
				Value: 100,
			},{
				From:  -1,
				To:    2,
				Value: 200,
			},{
				From:  1,
				To:    2,
				Value: 1,
			},{
				From:  1,
				To:    3,
				Value: 4,
			},
			{
				From:  0,
				To:    1,
				Value: 13,
			},{
				From:  2,
				To:    0,
				Value: 8,
			},{
				From:  2,
				To:    0,
				Value: 16,
			},
		},
	}
 */
let rollup4_2 = "0x0800000058000000dd9811cfc24ab8d56036a8eca90c7b8c75e35950f3aa514423ae2c6f66497d69f2fc899f0ad25b0041e46d84c206007982f93c0874152b8cf612798595ac9774cf32adb66f76726502fc0c223bce13e2ffffffff000000006400000000000000ffffffff02000000c800000000000000010000000200000001000000000000000100000003000000040000000000000000000000010000000d000000000000000200000000000000080000000000000002000000000000001000000000000000";
let header4_2 = "0x010000009917981ee62c603f923e899df91f2465d011148206f1d13659486eba99c6972c9e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae3100000000000000000000000000000000000000000000000000000000000000008327e12c9666c389375ea2e0336aa10deba2b0e8250a2bf2b2da5be54ffa7c01c6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8903d785f00000000";


/**
 * 	a0 := c.HexToAddress("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950")
 a1 := c.HexToAddress("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00")
 rollup := Rollup {
		Accounts:     [][20]byte{a0, a1},
		Transactions: []*Transaction{
			{
				From:  1,
				To:    0,
				Value: 1,
			},{
				From:  1,
				To:    0,
				Value: 4,
			},
			{
				From:  0,
				To:    1,
				Value: 13,
			},
		},
	}
 */
let rollup4_3 = "0x0800000030000000dd9811cfc24ab8d56036a8eca90c7b8c75e35950f3aa514423ae2c6f66497d69f2fc899f0ad25b00010000000000000001000000000000000100000000000000040000000000000000000000010000000d00000000000000";
let header4_3 = "0x020000004be9354a749658237c652d69269007ac600aa2f8615359e9e8fc106c6ba6c29b9e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae31000000000000000000000000000000000000000000000000000000000000000084be708be1e2535d5c3093306b1b86d3f71a190dfd5d7f15465f6ad05e1443b6c6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8903d785f00000000";


/** Accounts mixed
 * 0 -> 1
 * 1 -> 2
 * 2 -> 0
 * 4 -> 4
 * 		a2 := c.HexToAddress("0x41E46d84c206007982F93C0874152B8cF6127985")
 a0 := c.HexToAddress("0xDd9811Cfc24aB8d56036A8ecA90C7B8C75e35950")
 a1 := c.HexToAddress("0xf3AA514423aE2c6f66497D69f2fc899f0ad25b00")
 a3 := c.HexToAddress("0x95AC9774Cf32AdB66f76726502Fc0C223bCE13e2")
 rollup := Rollup {
		Accounts:     [][20]byte{a0, a1, a2, a3},
		Transactions: []*Transaction{
			{
				From:  1,
				To:    2,
				Value: 5,
			},{
				From:  1,
				To:    3,
				Value: 4,
			},
			{
				From:  0,
				To:    1,
				Value: 13,
			},{
				From:  2,
				To:    0,
				Value: 8,
			},{
				From:  2,
				To:    0,
				Value: 16,
			},
		},
	}
 */
let rollup4_4 = "0x080000005800000041e46d84c206007982f93c0874152b8cf6127985dd9811cfc24ab8d56036a8eca90c7b8c75e35950f3aa514423ae2c6f66497d69f2fc899f0ad25b0095ac9774cf32adb66f76726502fc0c223bce13e2010000000200000005000000000000000100000003000000040000000000000000000000010000000d000000000000000200000000000000080000000000000000000000020000001000000000000000";
let header4_4 = "0x03000000f8b76d89d9f6d1b4ac738655ce6cb805a4330bc672120013ecbc00d9d98d47a19e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae310000000000000000000000000000000000000000000000000000000000000000a614734684e067c14bcb2b8a9d2de85e347177a8d9c1765d4751b8d22851dd50c6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5ba55a81100e8391212d2f22fc6b84b36b5d02588c2a96c4db616268d8abe389b8903d785f00000000";
//let header4_4 = "0x01000000f5435028e33554fb2039b27eed98d2ed918ec528d9876928338f159716e19d45c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a4700000000000000000000000000000000000000000000000000000000000000000c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470e890f3815804618a4a18508208e77e4cc013309c7ed9f5bf63a17069562e6f5d4247e42484ae8910e5b16942b1802e337a01c8e18a80e7826e37eff9712995100020b44572f84116";




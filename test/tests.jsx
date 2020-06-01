var Rollups = artifacts.require('Rollups');

//	h1 := &pb.BlockHeader{
// 		Hash: crypto.Keccak256([]byte("Hash")),
// 		ParentHash: crypto.Keccak256([]byte("ParentHash")),
// 		QcHash:     crypto.Keccak256([]byte("QcHash")),
// 		DataHash:   crypto.Keccak256(data1),
// 		TxHash:     crypto.Keccak256([]byte("TxHash")),
// 		StateHash:  crypto.Keccak256([]byte("StateHash")),
// 		Height:     10,
// 		Timestamp:  time.Now().Unix(),
// 	}
let header = "0x0a20e46b55fcd8a51cfe1cd1de8eaaf6e5a9993d1e2e72b74f657f13638e3937f08a122006691b3a642e437e8d9e8afc33c44d37aed6fc1408804cc149baa62999512e161a20c6e9bc3e163dd8e600563396ed32279d729b1fb4a96345972e5fcb80d782be5b222019e376dbb4cca70f73994e2f86ae9f51b782a6da63953dfe4a1005608dd2b7ad2a209e3d0e49056d998b5007b06157f36de98c4ad14cc68dbb7ba553b8a45ea9ae3132207affdde4474baacd73cbd3437d946c841a0686171aff2bbf4b29a410b283e5e8380a40d0f8d4f605";

//	receipt1 := &mockReceipt{
// 		from:  common2.Address{},
// 		to:    account1,
// 		value: big.NewInt(100),
// 	}
// 	receipt2 := &mockReceipt{
// 		from:  common2.Address{},
// 		to:    account2,
// 		value: big.NewInt(200),
// 	}
// 	receipt3 := &mockReceipt{
// 		from:  common2.Address{},
// 		to:    account3,
// 		value: big.NewInt(300),
// 	}
// 	receipt4 := &mockReceipt{
// 		from:  common2.Address{},
// 		to:    account4,
// 		value: big.NewInt(400),
// 	}
let rollup1 = "0x0a1400000000000000000000000000000000000000000a14331bcceb099d3a66e1921c4e434fcbef853e2b300a14d166319b7eba5da39882b2b6d17e907801a772340a144595031751b620179ffc09f6e9db7a5016b53ee40a1441e46d84c206007982f93c0874152b8cf61279851204100118641205100218c8011205100318ac0212051004189003";
//	receipt5 := &mockReceipt{
// 		from:  account1,
// 		to:    account2,
// 		value: big.NewInt(10),
// 	}
// 	receipt6 := &mockReceipt{
// 		from:  account2,
// 		to:    account3,
// 		value: big.NewInt(20),
// 	}
// 	receipt7 := &mockReceipt{
// 		from:  account3,
// 		to:    account4,
// 		value: big.NewInt(30),
// 	}
let rollup2 = "0x0a14331bcceb099d3a66e1921c4e434fcbef853e2b300a14d166319b7eba5da39882b2b6d17e907801a772340a144595031751b620179ffc09f6e9db7a5016b53ee40a1441e46d84c206007982f93c0874152b8cf612798512041001180a1206080110021814120608021003181e";
//	receipt8 := &mockReceipt{
// 		from:  account2,
// 		to:    common2.Address{},
// 		value: big.NewInt(50),
// 	}
// 	receipt9 := &mockReceipt{
// 		from:  account3,
// 		to:    common2.Address{},
// 		value: big.NewInt(50),
// 	}
let rollup3 = "0x0a14d166319b7eba5da39882b2b6d17e907801a772340a1400000000000000000000000000000000000000000a144595031751b620179ffc09f6e9db7a5016b53ee41204100118321206080210011832\n";

let account1 = "0x331BcCEb099D3A66e1921C4e434FCBeF853e2B30";
let account2 = "0xd166319B7eBa5DA39882b2B6D17E907801a77234";
let account3 = "0x4595031751B620179FFC09f6E9DB7a5016B53ee4";
let account4 = "0x41E46d84c206007982F93C0874152B8cF6127985";

contract('Rollups simple test', async (accounts) => {
    it('Restricted access test', async () => {
        let instance = await Rollups.deployed();
        let h = Buffer.from(header.substring(2), 'hex');
        let r1  = Buffer.from(rollup1.substring(2), 'hex');
        //reverted()
        await notAuthorized(instance.addBlock(h, r1, {from: account1}));
        assert.equal(true, true)
    });

    it('Call GetHeight', async () => {
        let instance = await Rollups.deployed();
        let height = await instance.getTopHeight.call();
        assert.equal(height.valueOf(), 0);
    });

    it('Call AddBlock', async () => {
        let instance = await Rollups.deployed();

        let h = Buffer.from(header.substring(2), 'hex');
        let r1  = Buffer.from(rollup1.substring(2), 'hex');
        await instance.addBlock(h, r1);
        let height1 = await instance.getTopHeight.call();
        assert.equal(height1, 10);

        let balance11 = await instance.getBalance.call(account1);
        let balance21 = await instance.getBalance.call(account2);
        let balance31 = await instance.getBalance.call(account3);
        let balance41 = await instance.getBalance.call(account4);

        assert.equal(balance11.valueOf(), 100);
        assert.equal(balance21.valueOf(), 200);
        assert.equal(balance31.valueOf(), 300);
        assert.equal(balance41.valueOf(), 400);

        let r2  = Buffer.from(rollup2.substring(2), 'hex');
        await instance.addBlock(h, r2);
        let height2 = await instance.getTopHeight.call();
        assert.equal(height2, 10);

        let balance12 = await instance.getBalance.call(account1);
        let balance22 = await instance.getBalance.call(account2);
        let balance32 = await instance.getBalance.call(account3);
        let balance42 = await instance.getBalance.call(account4);

        assert.equal(balance12.valueOf(), 90);
        assert.equal(balance22.valueOf(), 190);
        assert.equal(balance32.valueOf(), 290);
        assert.equal(balance42.valueOf(), 430);

        let r3  = Buffer.from(rollup3.substring(2), 'hex');
        await instance.addBlock(h, r3);
        let height3 = await instance.getTopHeight.call();
        assert.equal(height3, 10);

        let balance13 = await instance.getBalance.call(account1);
        let balance23 = await instance.getBalance.call(account2);
        let balance33 = await instance.getBalance.call(account3);
        let balance43 = await instance.getBalance.call(account4);

        assert.equal(balance13.valueOf(), 90);
        assert.equal(balance23.valueOf(), 140);
        assert.equal(balance33.valueOf(), 240);
        assert.equal(balance43.valueOf(), 430);
    });
});


const PREFIX = "Returned error: VM Exception while processing transaction: ";

async function tryCatch(promise, message) {
    try {
        await promise;
        throw null;
    }
    catch (error) {
        assert(error, "Expected an error but did not get one");
        assert(error.message.startsWith(PREFIX + message), "Expected an error starting with '" + PREFIX + message + "' but got '" + error.message + "' instead");
    }
};
const catchRevert = async function(promise) {await tryCatch(promise, "revert"             );};
const catchOutOfGas = async function(promise) {await tryCatch(promise, "out of gas"         );};
const catchInvalidJump = async function(promise) {await tryCatch(promise, "invalid JUMP"       );};
const catchInvalidOpcode = async function(promise) {await tryCatch(promise, "invalid opcode"     );};
const catchStackOverflow  =  async function(promise) {await tryCatch(promise, "stack overflow"     );};
const catchStackUnderflow  = async function(promise) {await tryCatch(promise, "stack underflow"    );};
const catchStaticStateChange = async function(promise) {await tryCatch(promise, "static state change");};
const notAuthorized = async function(promise) {await tryCatch(promise, "revert Sender not authorized. -- Reason given: Sender not authorized..");};
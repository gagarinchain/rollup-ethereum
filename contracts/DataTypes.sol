pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

library DataTypes {

    event Offset(uint offset);


    struct Rollup {
        address[] accounts;
        Transaction[] transactions;
    }

    struct Transaction {
        int32 from;
        int32 to;
        uint64 value;
    }

    struct BlockHeader {
        bytes32 hash;
        bytes32 parentHash;
        bytes32 qcHash;
        bytes32 dataHash;
        bytes32 txHash;
        bytes32 stateHash;
        uint32 height;
        uint64 timestamp;
    }

    struct Signature {
        bytes bitmap;
        bytes signature;
    }

    function parseRollup(bytes memory rollup) public pure returns (Rollup memory) {

        uint offset = 0;
        uint32 aOffset = decodeUint32(rollup, offset);
        offset += 4;

        uint32 tOffset = decodeUint32(rollup, offset);
        offset += 4;

        uint accLength = (tOffset - aOffset) / 20;
        address[] memory accounts = new address[](accLength);

        uint txLength = (rollup.length - tOffset) / (4 + 4 + 8);
        Transaction[] memory txs = new Transaction[](txLength);

        uint o = aOffset;
        for (uint i=0; i < accLength; i++) {
            accounts[i] = decodeAddress(rollup, o);
            o += 20;
        }

        o = tOffset;
        for (uint i=0; i < txLength; i++) {
            Transaction memory tx = txs[i];
            tx.from = int32(decodeUint32(rollup, o));
            o += 4;
            tx.to = int32(decodeUint32(rollup, o));
            o += 4;
            tx.value = decodeUint64(rollup, o);
            o += 8;
        }

        return Rollup(accounts, txs);
    }

    function parseBlockHeader(bytes memory header) public pure returns (BlockHeader memory) {
        BlockHeader memory h;

        uint offset = 0;
        h.height = decodeUint32(header, offset);
        offset += 4;

        h.hash = decodeHash(header, offset);
        offset += 32;

        h.txHash = decodeHash(header, offset);
        offset += 32;

        h.stateHash = decodeHash(header, offset);
        offset += 32;

        h.dataHash = decodeHash(header, offset);
        offset += 32;

        h.qcHash = decodeHash(header, offset);
        offset += 32;

        h.parentHash = decodeHash(header, offset);
        offset += 32;

        h.timestamp = decodeUint64(header, offset);

        return h;
    }

    /**
     hh := &HashableHeader{
                Height:    uint32(h.height),
                TxHash:    h.txHash,
                StateHash: h.stateHash,
                DataHash:  h.dataHash,
                QcHash:    h.qcHash,
                Parent:    h.parent,
                Timestamp: uint64(h.timestamp.Unix()),
            }
    **/
    function serializeBlockHeaderForHash(BlockHeader memory header) public pure returns (bytes memory) {
        bytes memory bs = new bytes(4 + 32 + 32 + 32 + 32 + 32 + 8);

        uint offset = 0;
        encodeUint32(bs, offset, header.height);
        offset += 4;
        encodeHash(bs, offset, header.txHash);
        offset += 32;
        encodeHash(bs, offset, header.stateHash);
        offset += 32;
        encodeHash(bs, offset, header.dataHash);
        offset += 32;
        encodeHash(bs, offset, header.qcHash);
        offset += 32;
        encodeHash(bs, offset, header.parentHash);
        offset += 32;
        encodeUint64(bs, offset, header.timestamp);

        return bs;
    }

    function decodeUint32(bytes memory bs, uint p) internal pure returns (uint32) {
        uint varint = _decode_uint(p, bs, 4);
        return uint32(varint);
    }
    function encodeUint32(bytes memory bs, uint p, uint u) internal pure {
        _encode_uint(p, bs, 4, u);
    }

    function decodeUint64(bytes memory bs, uint p) internal pure returns (uint64) {
        uint varint = _decode_uint(p, bs, 8);
        return uint64(varint);
    }
    function encodeUint64(bytes memory bs, uint p, uint u) internal pure {
        _encode_uint(p, bs, 8, u);
    }

    function _encode_uint(uint p, bytes memory bs, uint sz, uint u) internal pure {
        assembly {
            let i := 0
            p     := add(add(bs, 0x20), p)
            for {} lt(i, sz) {} {
                mstore8(p, byte(sub(32, add(i, 1)), u))
                p := add(p, 0x01)
                i := add(i, 1)
            }
        }
    }

    function _decode_uint(uint p, bytes memory bs, uint sz) internal pure returns (uint) {
        uint x = 0;
        assembly {
            let i := 0
            p     := add(add(bs, 0x20), p)
            for {} lt(i, sz) {} {
                x:= add(shl(mul(8, i), byte(0, mload(p))), x)
            //x := or(x, mul(byte(0, mload(p)), exp(2, mul(8, i))))
                p := add(p, 0x01)
                i := add(i, 1)
            }
        }
        return (x);
    }

    function decodeAddress(bytes memory bs, uint256 p) internal pure returns (address) {
        require(bs.length >= (p + 20), "Read out of bounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(bs, 0x20), p)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function decodeHash(bytes memory bs, uint256 p) internal pure returns (bytes32) {
        require(bs.length >= (p + 32), "Read out of bounds");
        bytes32 tempAddress;

        assembly {
            tempAddress := mload(add(add(bs, 0x20), p))
        }

        return tempAddress;
    }

    function encodeHash(bytes memory bs, uint256 p, bytes32 h) internal pure {
        require(bs.length >= (p + 32), "Write out of bounds");

        assembly {
            mstore(add(add(bs, 0x20), p), h)
        }
    }

    function parseAndValidate(bytes memory blockHeader, bytes memory rollup) public pure returns (BlockHeader memory h, Rollup memory r) {
        h = parseBlockHeader(blockHeader);
        r = parseRollup(rollup);

        bytes32 original = h.dataHash;
        bytes32 toValidate = keccak256(rollup);
        require(
            original == h.dataHash,
            "Data hash is not valid"
        );

        bytes32 hash = h.hash;
        bytes32 empty;
        h.hash = empty;
        bytes memory b = serializeBlockHeaderForHash(h);
        h.hash = hash;
        bytes32 calculated = keccak256(b);

        require(
            h.hash == calculated,
            "Not valid header hash"
        );

    }

}
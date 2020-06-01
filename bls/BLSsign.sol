pragma solidity ^0.4.0;

library BLSSignature {
    // NOTE: BLS12-381 precompile addresses are placeholders
    uint8 constant BLS12_381_PAIRING_PRECOMPILE_ADDRESS = 0xA;
    uint8 constant BLS12_381_MAP_FIELD_TO_CURVE_PRECOMPILE_ADDRESS = 0xB;
    uint8 constant BLS12_381_G2_ADD_ADDRESS = 0xC;
    uint8 constant BLS12_381_G2_MULTIPLY_ADDRESS = 0xD;
    string constant BLS_SIG_DST = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+";
    uint8 constant MOD_EXP_PRECOMPILE_ADDRESS = 0x5;

    // Fp is a field element with the high-order part stored in `a`.
    struct Fp {
        uint a;
        uint b;
    }

    // Fp2 is an extension field element with the coefficient of the
    // quadratic non-residue stored in `b`, i.e. p = a + i * b
    struct Fp2 {
        Fp a;
        Fp b;
    }

    // G1Point represents a point on BLS12-381 over Fp with coordinates (X,Y);
    struct G1Point {
        Fp X;
        Fp Y;
    }

    // G2Point represents a point on BLS12-381 over Fp2 with coordinates (X,Y);
    struct G2Point {
        Fp2 X;
        Fp2 Y;
    }

    function expandMessage(bytes32 message) private pure returns (bytes memory) {
        bytes memory b0Input = new bytes(143);
        for (uint i = 0; i < 32; i++) {
            b0Input[i+64] = message[i];
        }
        b0Input[96] = 0x01;
        for (uint i = 0; i < 44; i++) {
            b0Input[i+99] = bytes(BLS_SIG_DST)[i];
        }

        bytes32 b0 = sha256(abi.encodePacked(b0Input));

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(abi.encodePacked(b0, byte(0x01), bytes(BLS_SIG_DST)));
        assembly {
            mstore(add(output, 0x20), chunk)
        }
        for (uint i = 2; i < 9; i++) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(abi.encodePacked(input, byte(uint8(i)), bytes(BLS_SIG_DST)));
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        }

        return output;
    }

    function sliceToUint(bytes memory data, uint start, uint end) private pure returns (uint) {
        uint length = end - start;
        assert(length >= 0);
        assert(length <= 32);

        uint result;
        for (uint i = 0; i < length; i++) {
            byte b = data[start+i];
            result = result + (uint8(b) * 2**(8*(length-i-1)));
        }
        return result;
    }

    // Reduce the number encoded as the big-endian slice of data[start:end] modulo the BLS12-381 field modulus.
    // Copying of the base is cribbed from the following:
    // https://github.com/ethereum/solidity-examples/blob/f44fe3b3b4cca94afe9c2a2d5b7840ff0fafb72e/src/unsafe/Memory.sol#L57-L74
    function reduceModulo(bytes memory data, uint start, uint end) private view returns (bytes memory) {
        uint length = end - start;
        assert (length >= 0);
        assert (length <= data.length);

        bytes memory result = new bytes(48);

        bool success;
        assembly {
            let p := mload(0x40)
        // length of base
            mstore(p, length)
        // length of exponent
            mstore(add(p, 0x20), 0x20)
        // length of modulus
            mstore(add(p, 0x40), 48)
        // base
        // first, copy slice by chunks of EVM words
            let ctr := length
            let src := add(data, 0x20)
            let dst := add(p, 0x60)
            for { }
            or(gt(ctr, 0x20), eq(ctr, 0x20))
            { ctr := sub(ctr, 0x20) }
            {
                mstore(dst, mload(src))
                dst := add(dst, 0x20)
                src := add(src, 0x20)
            }
        // next, copy remaining bytes in last partial word
            let mask := sub(exp(256, sub(0x20, ctr)), 1)
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dst), mask)
            mstore(dst, or(destpart, srcpart))
        // exponent
            mstore(add(p, add(0x60, length)), 1)
        // modulus
            let modulusAddr := add(p, add(0x60, add(0x10, length)))
            mstore(modulusAddr, or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7)) // pt 1
            mstore(add(p, add(0x90, length)), 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab) // pt 2
            success := staticcall(
            sub(gas(), 2000),
            MOD_EXP_PRECOMPILE_ADDRESS,
            p,
            add(0xB0, length),
            add(result, 0x20),
            48)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success, "call to modular exponentiation precompile failed");
        return result;
    }

    function convertSliceToFp(bytes memory data, uint start, uint end) private view returns (Fp memory) {
        bytes memory fieldElement = reduceModulo(data, start, end);
        uint a = sliceToUint(fieldElement, 32, 48);
        uint b = sliceToUint(fieldElement, 0, 32);
        return Fp(a, b);
    }

    function hashToField(bytes32 message) private view returns (Fp2[2] memory result) {
        bytes memory some_bytes = expandMessage(message);
        result[0] = Fp2(
            convertSliceToFp(some_bytes, 0, 64),
            convertSliceToFp(some_bytes, 64, 128)
        );
        result[1] = Fp2(
            convertSliceToFp(some_bytes, 128, 192),
            convertSliceToFp(some_bytes, 192, 256)
        );
    }

    function mapToCurve(Fp2 memory input) private view returns (G2Point memory result) {
        bool success;
        assembly {
            success := staticcall(
            sub(gas(), 2000),
            BLS12_381_MAP_FIELD_TO_CURVE_PRECOMPILE_ADDRESS,
            input,
            128,
            result,
            256
            )
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success, "call to map to curve precompile failed");
    }

    function addG2(G2Point memory a, G2Point memory b) private view returns (G2Point memory result) {
        uint[16] memory input;
        input[0]  = a.X.a.a;
        input[1]  = a.X.a.b;
        input[2]  = a.X.b.a;
        input[3]  = a.X.b.b;
        input[4]  = a.Y.a.a;
        input[5]  = a.Y.a.b;
        input[6]  = a.Y.b.a;
        input[7]  = a.Y.b.b;

        input[8]  = b.X.a.a;
        input[9]  = b.X.a.b;
        input[10] = b.X.b.a;
        input[11] = b.X.b.b;
        input[12] = b.Y.a.a;
        input[13] = b.Y.a.b;
        input[14] = b.Y.b.a;
        input[15] = b.Y.b.b;

        bool success;
        assembly {
            success := staticcall(
            sub(gas(), 2000),
            BLS12_381_G2_ADD_ADDRESS,
            input,
            512,
            result,
            256
            )
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success, "call to addition in G2 precompile failed");
    }

    // Implements "hash to the curve" from the IETF BLS draft.
    function hashToCurve(bytes32 message) private view returns (G2Point memory) {
        Fp2[2] memory messageElementsInField = hashToField(message);
        G2Point memory firstPoint = mapToCurve(messageElementsInField[0]);
        G2Point memory secondPoint = mapToCurve(messageElementsInField[1]);
        return addG2(firstPoint, secondPoint);
    }

    function pairing(G1Point memory u, G2Point memory v) private view returns (bytes32 result) {
        uint[12] memory input;

        input[0] =  u.X.a;
        input[1] =  u.X.b;
        input[2] =  u.Y.a;
        input[3] =  u.Y.b;

        input[4] =  v.X.a.a;
        input[5] =  v.X.a.b;
        input[6] =  v.X.b.a;
        input[7] =  v.X.b.b;
        input[8] =  v.Y.a.a;
        input[9] =  v.Y.a.b;
        input[10] = v.Y.b.a;
        input[11] = v.Y.b.b;

        bool success;
        assembly {
            success := staticcall(
            sub(gas(), 2000),
            BLS12_381_PAIRING_PRECOMPILE_ADDRESS,
            input,
            384,
            result,
            32
            )
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success, "call to pairing precompile failed");
    }

    // Return -P1, negative of the generator of the group G1.
    // NOTE: computed via: for G1 = (x,y), -G1 = (x, -y)
    function negativeP1() private pure returns (G1Point memory) {
        return G1Point(
            Fp(
                31827880280837800241567138048534752271,
                88385725958748408079899006800036250932223001591707578097800747617502997169851
            ),
            Fp(
                22997279242622214937712647648895181298,
                46816884707101390882112958134453447585552332943769894357249934112654335001290
            )
        );
    }

    function decodeG1Point(bytes memory encodedX, Fp memory Y) private pure returns (G1Point memory) {
        uint a = sliceToUint(encodedX, 32, 48);
        uint b = sliceToUint(encodedX, 0, 32);
        Fp memory X = Fp(a, b);
        return G1Point(X,Y);
    }

    function decodeG2Point(bytes memory encodedX, Fp2 memory Y) private pure returns (G2Point memory) {
        uint aa = sliceToUint(encodedX, 32, 48);
        uint ab = sliceToUint(encodedX, 0, 32);
        uint ba = sliceToUint(encodedX, 80, 96);
        uint bb = sliceToUint(encodedX, 48, 80);
        Fp2 memory X = Fp2(
            Fp(aa, ab),
            Fp(ba, bb)
        );
        return G2Point(X, Y);
    }

    function isValid(
        bytes32 message,
        bytes memory encodedPublicKey,
        bytes memory encodedSignature,
        Fp memory publicKeyYCoordinate,
        Fp2 memory signatureYCoordinate
    ) internal view returns (bool) {
        G1Point memory publicKey = decodeG1Point(encodedPublicKey, publicKeyYCoordinate);
        G2Point memory signature = decodeG2Point(encodedSignature, signatureYCoordinate);
        G2Point memory messageOnCurve = hashToCurve(message);

        bytes32 firstPairing = pairing(publicKey, messageOnCurve);
        bytes32 secondPairing = pairing(negativeP1(), signature);
        return (uint(firstPairing) * uint(secondPairing)) == 1;
    }
}
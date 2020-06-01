pragma solidity ^0.4.0;

import './rollup_pb.sol';

contract Rollups {
    using pb_Rollup for pb_Rollup.Data;

    int32 topHeight;
    mapping(address => int64) balances;
    address[] public committee ;

    event BalanceChanged(address owner, int64 balance);
    event Transaction(uint256 tranIndex);
    event Received(uint256 blockCount);
    event TopHeightUpdate(int32 eight);

    constructor(address[] c) public {
        committee = c;
    }

    modifier withCommittee() {
        bool allowed = false;
        for (uint i = 0; i < committee.length; i++) {
            if (committee[i] == msg.sender) {
                allowed = true;
            }
        }
        require(
            allowed,
            "Sender not authorized."
        );
        _;
    }

    function getTopHeight() public withCommittee view returns (int32) {
        return topHeight;
    }

    function addBlock(bytes header, bytes rollup) public withCommittee {
        pb_BlockHeader.Data memory h = pb_BlockHeader.decode(header);
        pb_Rollup.Data memory r = pb_Rollup.decode(rollup);
        emit TopHeightUpdate(int32(r.transactions[0].value));

        for (uint i = 0; i < r.transactions.length; i++) {
            emit Transaction(i);
            pb_Transaction.Data memory tran = r.transactions[i];

            applyTransaction(tran, r.accounts);
        }

        topHeight = h.height;
    }

    function getBalance(address owner) public returns (int64) {
        return balances[owner];
    }

    function applyTransaction(pb_Transaction.Data memory tran, bytes[] memory accounts) private {
        int64 value = tran.value;
        if (tran.from >= 0) {
            address from = bytesToAddress(accounts[uint32(tran.from)]);
            if(balances[from] != 0) {
                balances[from] = balances[from] - value;
                emit BalanceChanged(from, balances[from]);
            }
        }

        if (tran.to >= 0) {
            address to = bytesToAddress(accounts[uint32(tran.to)]);
            if(balances[to] != 0) {
                balances[to] = balances[to] + value;
            } else {
                balances[to] = value;
            }
            emit BalanceChanged(to, balances[to]);
        }
    }

    function tb20(bytes memory _b) public pure returns (bytes20 _result) {
        assembly {
            _result := mload(add(_b, 0x20))
        }
    }

    function bytesToAddress(bytes memory _b) public returns (address) {
        return address(tb20(_b));
    }
}

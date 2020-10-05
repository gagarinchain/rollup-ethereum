pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Gateway.sol";
import {DataTypes as dt} from "./DataTypes.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Rollups {
    uint32 topHeight = 0;
    uint32 blockInterval = 1;
    mapping(address => uint256) balances;
    address[] public committee ;
    Gateway gateway;

    using SafeMath for uint256;

    event BalanceChanged(address owner, uint256 balance);
    event Transaction(uint256 tranIndex);
    event Received(uint256 blockCount);
    event TopHeightUpdate(uint32 height);

    constructor(address[] memory c, address _gateway) public {
        committee = c;
        gateway = Gateway(_gateway);
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
            "Sender not authorized"
        );
        _;
    }

    function getTopHeight() public view returns (uint32) {
        return topHeight;
    }

    function addBlock(bytes memory header, bytes memory rollup, bytes memory signature) public withCommittee {
        (dt.BlockHeader memory h, dt.Rollup memory r) = dt.parseAndValidate(header, rollup);

        require(
            h.height == topHeight + blockInterval,
            "Not valid block"
        );

        if (r.transactions.length > 0) {
            for (uint i = 0; i < r.transactions.length; i++) {
                emit Transaction(i);
                dt.Transaction memory tran = r.transactions[i];

                applyTransaction(tran, r.accounts);
            }
        }

        emit TopHeightUpdate(h.height);
        topHeight = h.height;
    }

    function getBalance(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function applyTransaction(dt.Transaction memory tran, address[] memory accounts) private {
        uint256 value = tran.value;

        //bad transaction
        if (tran.from == -1 && tran.to == -1) {
            return;
        }

        //deposit
        if (tran.from == -1) {
            address to = accounts[uint32(tran.to)];
            increaseBalance(to, value);
            gateway.confirmDeposit(to);
            return;
        }

        //redeem
        if (tran.to == -1) {
            address from = accounts[uint32(tran.from)];
            decreaseBalance(from, value);
            gateway.returnDeposit(from, value);
            return;
        }

        if (tran.from == tran.to) { //self transaction, do nothing, otherwise we can double spend
            return;
        }

        //we can check, if client is registered and transaction is allowed only through request to gateway,
        //but actually we must check it through rollup plugin in Gagarin.network
        address from = accounts[uint32(tran.from)];
        address to = accounts[uint32(tran.to)];
        decreaseBalance(from, value);
        increaseBalance(to, value);
    }

    function decreaseBalance(address from, uint256 value) private {
        balances[from] > 0;
        balances[from] = balances[from] - value;
        emit BalanceChanged(from, balances[from]);
    }

    function increaseBalance(address to, uint256 value) private {
        balances[to] = balances[to] + value;
        emit BalanceChanged(to, balances[to]);
    }
}

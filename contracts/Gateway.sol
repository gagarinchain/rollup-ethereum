pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface RollupsManager {

}

contract Gateway {
    struct Pending {
        uint256 amount;
        uint blockNumber;
    }

    event DepositCancelled(address sender, uint256 delta);
    event DepositConfirmed(address sender, uint256 amount);
    event DepositReturned(address sender, uint256 amount);
    event Registered(address eth, address gagarin);
    event Unregistered(address eth);


    using SafeERC20 for IERC20;

    IERC20 public token;
    address public governance;
    address public rollupsManager;
    uint32 public pendingTTL;

    //eth to gagarin address mapping
    mapping (address => address) private ethToGagarin;
    //gagarin to eth address mapping
    mapping (address => address) private gagarinToEth;
    //pending deposits
    mapping (address => Pending) private pending;

    //pass token we work with
    constructor (address _token) public {
        token = IERC20(_token);
        governance = msg.sender;
        pendingTTL = 32;
    }

    //changes government address
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    //sets address of rollups contract
    function setRollupManager(address _manager) public {
        require(msg.sender == governance, "!governance");
        rollupsManager = _manager;
    }

    //deposit amount of token to contract
    //creates pending record and transfers tokens
    function lockTokens(uint _amount) public {
        require(ethToGagarin[msg.sender] != address(0x0), "!registered");

        token.safeTransferFrom(msg.sender, address(this), _amount);
        addPending(msg.sender, _amount);
    }


    //changes time to live of pending record
    function changePendingTTL(uint32 newTTL) public {
        require(msg.sender == governance, "!governance");
        pendingTTL = newTTL;
    }

    function addPending(address sender, uint _amount) private {
        if (pending[sender].blockNumber != 0) {
            revert("!pendingNotExpired");
        }

        pending[sender] = Pending(_amount, block.number);
    }

    //confirms deposit record, this happens when gagarin network agreed deposit and increased balance
    function confirmDeposit(address gagarinOwner) public {
        require(msg.sender == rollupsManager, "!rollupsManager");
        address ethAddr = gagarinToEth[gagarinOwner];
        Pending memory p = pending[ethAddr];
        pending[ethAddr] = Pending(0, 0);

        emit DepositConfirmed(ethAddr, p.amount);
    }

    //returns deposit, it happens when token is redeemed in gagarin network and balance decreased
    function returnDeposit(address gagarinOwner, uint256 _amount) public{
        require(msg.sender == rollupsManager, "!rollupsManager");

        address ethAddr = gagarinToEth[gagarinOwner];
        token.safeTransfer(ethAddr, _amount);

        emit DepositReturned(ethAddr, _amount);
    }

    //returns pending record when TTL expired, must be called by pending creator
    function cancelDeposit() public {
        Pending memory p = pending[msg.sender];
        if (p.blockNumber == 0) {
            revert("!noDepositToCancel");
        }

        uint256 delta = block.number - p.blockNumber;
        if (delta <= pendingTTL) {
            revert("!depositIsNotExpiredYet");
        }
        //return tokens
        token.safeTransferFrom(address(this), msg.sender, p.amount);
        pending[msg.sender] = Pending(0, 0);
        emit DepositCancelled(msg.sender, delta);
    }

    //registers ethereum account and binds gagarin.network address to it
    function register(address gAddress) public {
        if (ethToGagarin[msg.sender] != address(0x0)) {
            revert("!doubleRegistrationEth");
        }
        if (gagarinToEth[gAddress] != address(0x0)) {
            revert("!doubleRegistrationGagarin");
        }

        ethToGagarin[msg.sender] = gAddress;
        gagarinToEth[gAddress] = msg.sender;

        emit Registered(msg.sender, gAddress);
    }

    //unregisters ethereum account and frees gagarin.network address
    function unregister() public {
        address gAddr = ethToGagarin[msg.sender];
        if (gAddr == address(0x0)) {
            revert("!noAddrFound");
        }

        if (pending[msg.sender].blockNumber > 0) {
            revert("!pendingDepositFound");
        }

        ethToGagarin[msg.sender] = address(0x0);
        gagarinToEth[gAddr] = address(0x0);

        emit Unregistered(msg.sender);
    }

}

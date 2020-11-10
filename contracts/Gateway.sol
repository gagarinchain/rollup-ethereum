pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

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
    mapping (address => Pending) private pendings;

    //pass token we work with
    constructor (address _token) public {
        token = IERC20(_token);
        governance = msg.sender;
        pendingTTL = 32;
    }

    modifier withGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }
    modifier withManager() {
        require(msg.sender == rollupsManager, "!rollupsManager");
        _;
    }

    //changes government address
    function setGovernance(address _governance) public withGovernance {
        governance = _governance;
    }

    //sets address of rollups contract
    function setRollupManager(address _manager) public withGovernance {
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
    function changePendingTTL(uint32 newTTL) public withGovernance {
        pendingTTL = newTTL;
    }

    function addPending(address sender, uint _amount) private {
        if (pendings[sender].blockNumber != 0) {
            revert("!pendingNotExpired");
        }

        pendings[sender] = Pending(_amount, block.number);
    }

    //confirms deposit record, this happens when gagarin network agreed deposit and increased balance
    function confirmDeposit(address gagarinOwner) public withManager {
        address ethAddr = gagarinToEth[gagarinOwner];
        Pending memory p = pendings[ethAddr];
        pendings[ethAddr] = Pending(0, 0);

        emit DepositConfirmed(ethAddr, p.amount);
    }

    //returns deposit, it happens when token is redeemed in gagarin network and balance decreased
    function returnDeposit(address gagarinOwner, uint256 _amount) public withManager {
        address ethAddr = gagarinToEth[gagarinOwner];
        token.safeTransfer(ethAddr, _amount);

        emit DepositReturned(ethAddr, _amount);
    }

    //returns pending record when TTL expired, must be called by pending creator
    function cancelDeposit() public {
        Pending memory p = pendings[msg.sender];
        if (p.blockNumber == 0) {
            revert("!noDepositToCancel");
        }

        uint256 delta = block.number - p.blockNumber;
        if (delta <= uint256(pendingTTL)) {
            revert("!depositIsNotExpiredYet");
        }
        //return tokens
        token.safeTransfer(msg.sender, p.amount);
        pendings[msg.sender] = Pending(0, 0);
        emit DepositCancelled(msg.sender, delta);
    }

    function getPending(address gAddress) public view returns (Pending memory) {
        address ethAddress = gagarinToEth[gAddress];
        return pendings[ethAddress];
    }

    //registers ethereum account and binds gagarin.network address to it
    function register(address ethAddress, address gAddress) public withGovernance {
        if (ethToGagarin[ethAddress] != address(0x0)) {
            revert("!doubleRegistrationEth");
        }
        if (gagarinToEth[gAddress] != address(0x0)) {
            revert("!doubleRegistrationGagarin");
        }

        ethToGagarin[ethAddress] = gAddress;
        gagarinToEth[gAddress] = ethAddress;

        emit Registered(ethAddress, gAddress);
    }

    function isRegistered(address ethAddress, address gAddress) public view returns (bool) {
        if (ethAddress == address(0x0)) {
            if (gAddress == address(0x0)) {
                return false;
            }
            return gagarinToEth[gAddress] == address(0x0);
        }
        return ethToGagarin[ethAddress] == address(0x0);
    }


    //unregisters ethereum account and frees gagarin.network address
    function unregister(address ethAddress) public withGovernance {

        address gAddr = ethToGagarin[ethAddress];
        if (gAddr == address(0x0)) {
            revert("!noAddrFound");
        }

        if (pendings[ethAddress].blockNumber > 0) {
            revert("!pendingDepositFound");
        }

        ethToGagarin[ethAddress] = address(0x0);
        gagarinToEth[gAddr] = address(0x0);

        emit Unregistered(ethAddress);
    }

}

pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Rollups.sol";

contract TestRollups {

    function testInitialTopHeight() {
        Rollups rollups = Rollups(DeployedAddresses.Rollups());
        int expected = 1;
        Assert.equal(rollups.getTopHeight(), expected, "Initial top height must be zero");

        Assert.equal(rollups.getTopHeight(), expected, "Initial top height must be zero");

        Assert.equal(rollups.getTopHeight(), expected, "Initial top height must be zero");
    }

}
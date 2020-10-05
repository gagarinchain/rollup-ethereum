const Web3Utils = require('web3-utils');
module.exports = {
    web3Utils: Web3Utils,
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*",
            gas:6283185,
        },
        "rinkeby": {
            host: "192.168.1.189",
            port: 8545,
            from:"0x8185726EDb012D1A0A53f50c218B1Ed1bBaD7fE3",
            network_id: "*",
        }
    },
    compilers: {
        solc: {
            version: "0.5.16" // ex:  "0.4.20". (Default: Truffle's installed solc)
        }
    }
};
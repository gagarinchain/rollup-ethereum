const Web3Utils = require('web3-utils');
module.exports = {
    web3Utils: Web3Utils,
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*"
        }
    },
    compilers: {
        solc: {
            version: "0.4.26" // ex:  "0.4.20". (Default: Truffle's installed solc)
        }
    }
};
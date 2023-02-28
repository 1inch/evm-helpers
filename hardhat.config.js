require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-waffle');
require('dotenv').config();
require('hardhat-deploy');
require('hardhat-gas-reporter');
require('solidity-coverage');

const { networks, etherscan } = require('./hardhat.networks');

module.exports = {
    mocha: {
        timeout: 100000,
    },
    etherscan,
    solidity: {
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000000,
            },
        },
        version: '0.8.15',
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    networks,
};

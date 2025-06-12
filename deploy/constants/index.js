const weth = require('./weth');
const feeCollectorOwner = require('./fee-collector-owner');
const feeCollectorFactory = require('./fee-collector-factory');
const feeCollectorFactoryOwner = require('./fee-collector-factory-owner');
const lop = require('./lop');
const create3Deployer = require('./create3-deployer');
const operator = require('./fee-collector-operator');
const uniV4constructorArgs = require('./uni-v4-helper-args');
const leftoverExchangerOwner = require('./leftover-exchanger-owner');

module.exports = {
    WETH: weth,
    FEE_COLLECTOR_OWNER: feeCollectorOwner,
    FEE_COLLECTOR_FACTORY: feeCollectorFactory,
    FEE_COLLECTOR_FACTORY_OWNER: feeCollectorFactoryOwner,
    LOP: lop,
    CREATE3_DEPLOYER_CONTRACT: create3Deployer,
    FEE_COLLECTOR_OPERATOR: operator,
    CONSTRUCTOR_ARGS: {
        UniV4Helper: uniV4constructorArgs,
    },
    LEFTOVER_EXCHANGER_OWNER: leftoverExchangerOwner,
};

module.exports.skip = async () => true;

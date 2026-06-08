const constantsData = require('./constants.json');

function sliceArgs (args, expectedSize) {
    let res = {}; // eslint-disable-line prefer-const
    for (const [key, value] of Object.entries(args)) {
        if (!isNaN(Number(key)) && Array.isArray(value)) {
            res[key] = value.slice(0, expectedSize);
        }
    }
    return res;
}

module.exports = {
    WETH: constantsData.weth || {},
    FEE_COLLECTOR_OWNER: constantsData.feeCollectorOwner || {},
    FEE_COLLECTOR_SALT: constantsData.feeCollectorSalt || {},
    FEE_COLLECTOR_FACTORY: constantsData.feeCollectorFactory || {},
    FEE_COLLECTOR_FACTORY_OWNER: constantsData.feeCollectorFactoryOwner || {},
    FEE_COLLECTOR_FACTORY_SALT: constantsData.feeCollectorFactorySalt || {},
    LOP: constantsData.lop || {},
    CREATE3_DEPLOYER_CONTRACT: constantsData.create3DeployerContract || {},
    FEE_COLLECTOR_OPERATOR: constantsData.feeCollectorOperator || {},
    CONSTRUCTOR_ARGS: {
        UniV4Helper: constantsData.constructorArgs?.UniV4Helper || {},
        UniV4HelperV2: sliceArgs(constantsData.constructorArgs?.UniV4Helper || {}, 2),
    },
    LEFTOVER_EXCHANGER_OWNER: constantsData.leftoverExchangerOwner || {},
    LEFTOVER_EXCHANGER_SALT: constantsData.leftoverExchangerSalt || {},
};

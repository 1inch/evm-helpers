## CONTRACTS DEPLOYMENT

Deployment of contracts may be done either manually or via an automated pipeline using Make.

For manual deployment, configure the constants in `config/constants.json` for the specific network.

For automatic deployment, we use `make` and Makefiles. The Makefile manages the deployment and configuration of various smart contracts and helpers, including targets for installing dependencies, deploying contracts, and managing environment variables.

## QUICK START

1. Create `.env` file based on the examples below and fill in values
2. Run `make install` to install dependencies
3. Run `make deploy-all` to deploy all contracts

## OVERVIEW

The deployment process includes the following steps:
1. Define environment parameters in `.env`. For automated deployments, you can also use `.env.automation` by setting `OPS_LAUNCH_MODE=auto`.
2. To install dependencies, run `make install`.
3. To deploy all contracts, use `make deploy-all`. It will automatically read the configuration from `.env` (or `.env.automation` if `OPS_LAUNCH_MODE=auto`) and deploy all contracts step by step. If any deployment fails, check the configuration and restart the process.
4. To deploy a single contract type, you can use the following commands:
    - `make deploy-helpers` deploys all helper contracts defined in `OPS_EVM_HELPER_CONFIGS`,
    - `make deploy-leftover-exchanger` deploys LeftoverExchanger,
    - `make deploy-fee-collector-factory` deploys FeeCollector and FeeCollectorFactory,
    - `make deploy-new-fee-collector` deploys specific FeeCollectors defined in `OPS_FEE_COLLECTOR_OPERATORS` and `OPS_FEE_COLLECTOR_OPERATOR_NAMES`,
    - `make upgrade-fee-collector` upgrades the FeeCollector implementation.
5. To get deployed contract addresses, use `make get PARAMETER=<param>` where `<param>` is the contract parameter name (e.g., `OPS_EVM_HELPERS_ADDRESS`).

## ENVIRONMENT VARIABLES

### Core Variables
- `OPS_NETWORK`: The name of the network to deploy to (e.g., mainnet, arbitrum, localhost).
- `OPS_CHAIN_ID`: The chain ID of the network.
- `OPS_DEPLOYMENT_METHOD`: Deployment method (default: "create3", can be changed to "create2" or others).
- `OPS_ZKSYNC_MODE`: A boolean indicating if ZKSync mode is enabled (automatically set to true for chain ID 324).
- `OPS_LAUNCH_MODE`: If set to "auto", uses `.env.automation` instead of `.env`.

### Helper Contracts
- `OPS_EVM_HELPER_CONFIGS`: Configuration for EVM helper contracts to deploy (replaces old OPS_HELPER_NAMES).
- `OPS_UNIV4HELPER_ARGS`: Arguments for the UniV4Helper contract (JSON array format).
- `MAINNET_RPC_URL`: RPC URL for mainnet (required when OPS_NETWORK is "hardhat").

### Common Contract Addresses
- `OPS_WETH_ADDRESS`: The address of the WETH contract.
- `OPS_CREATE3_DEPLOYER_ADDRESS`: The address of the Create3 Deployer contract (not required for ZKSync mode).
- `OPS_LOP_ADDRESS`: The address of the LOP contract.

### LeftoverExchanger
- `OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS`: The owner address for the LeftoverExchanger.
- `OPS_LEFTOVER_EXCHANGER_SALT`: Salt for LeftoverExchanger deployment (required for create3 deployment method, except for chain ID 324).

### FeeCollector
- `OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS`: The owner address for the Fee Collector Factory.
- `OPS_FEE_COLLECTOR_OWNER_ADDRESS`: The owner address for the Fee Collector.
- `OPS_FEE_COLLECTOR_OPERATORS`: Comma-separated list of operator addresses for new fee collectors.
- `OPS_FEE_COLLECTOR_OPERATOR_NAMES`: Comma-separated list of operator names corresponding to the addresses.

Note: For ZKSync (chain ID 324), `OPS_ZKSYNC_MODE` is automatically set to true and `OPS_CREATE3_DEPLOYER_ADDRESS` is not required.

## MAKEFILE TARGETS

Here is a list of main Makefile targets you can use by running `make <target-name>` in the terminal:

### Installation and Setup
- `install`: Install both utilities and dependencies
- `install-utils`: Install necessary utilities like yarn, wget, and jq
- `install-dependencies`: Install project dependencies using yarn
- `clean`: Remove all deployment files for the specified network

### Deployment Targets
- `deploy-all`: Deploy all contracts (helpers, leftover exchanger, fee collector factory, and new fee collectors)
- `deploy-helpers`: Deploy helper contracts specified in `OPS_EVM_HELPER_CONFIGS`
- `deploy-leftover-exchanger`: Deploy the LeftoverExchanger contract
- `deploy-fee-collector-factory`: Deploy the FeeCollectorFactory contract (uses ZKSync-specific deployment if OPS_ZKSYNC_MODE is true)
- `deploy-new-fee-collector`: Deploy new FeeCollector contracts for specified operators
- `upgrade-fee-collector`: Upgrade the FeeCollector implementation (uses ZKSync-specific upgrade if OPS_ZKSYNC_MODE is true)

### Utility Targets
- `get PARAMETER=<param>`: Get deployed contract address (e.g., `make get PARAMETER=OPS_EVM_HELPERS_ADDRESS`)
- `get-outputs`: Get all available contract address parameters for the current network
- `help`: Show available targets and their descriptions

### Internal Validation Targets (called automatically)
- `validate-helpers`: Validate environment variables for helper deployment
- `validate-leftover-exchanger`: Validate environment variables for LeftoverExchanger deployment
- `validate-fee-collector-factory`: Validate environment variables for FeeCollectorFactory deployment
- `validate-new-fee-collector`: Validate environment variables for new FeeCollector deployment
- `validate-upgrade-fee-collector`: Validate environment variables for FeeCollector upgrade

## DEPLOYMENT FLOW

1. The Makefile automatically manages the skip status of deployment files to ensure only the desired contracts are deployed.
2. Environment variables are validated before deployment to ensure all required parameters are set.
3. Constants are automatically updated in `config/constants.json` based on the chain ID.
4. Each deployment can be run independently, and the system tracks deployed contract addresses.

## ISSUES

- If the deployment pipeline breaks, you can reset all deployments to be skippable by running `make deploy-skip-all`, then run individual deployment targets.
- Be careful with `make clean` - it removes all deployments in `./deployments/$(OPS_NETWORK)`.
- When using create3 deployment method (default), ensure the Create3 Deployer is already deployed on the target network (except for ZKSync).

## NOTES

- The Makefile automatically strips quotes from environment variables.
- ZKSync mode is automatically enabled for chain ID 324.
- The deployment method defaults to "create3" if not specified.
- All contract addresses and configuration are stored in `config/constants.json` organized by chain ID.

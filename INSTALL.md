

## CONTRACTS DEPLOYMENT

Deployment of contracts may be done either manually or via an automated pipeline.

For manual deployment, configure the constants in `./deploy/constants/*.js` for the specific network (for example, add a `chainID: your_parameter,` line to each file as needed).

For automatic deployment, we use `make` and Makefiles. The Makefile manages the deployment and configuration of various smart contracts and helpers, including targets for installing dependencies, deploying contracts, and managing environment variables.

## QUICK START

1. Run `make env-example` → creates `.env.example`
2. Move `.env.example` to `.env` and fill in values
3. Run `make install`
4. **Optional only for local Hardhat node**: Run `NODE_RPC=[PUT_HERE_THE_RPC_URL_FOR_FORKING] make launch-hh-node`
5. Run `make deploy-all`

## OVERVIEW

The deployment process includes the following steps:
1. Define environment parameters in `.env`. Run `make env-example` in the terminal to generate an example configuration file `.env.example`. Rename this file to `.env` and set the correct values.
2. To install dependencies, run `make install`.
3. To deploy to a local node (for example, a Hardhat node), use the command `NODE_RPC=[PUT_HERE_THE_RPC_URL_FOR_FORKING] make launch-hh-node`. This will launch a local Hardhat node on `http://127.0.0.1:8545`, forked from the latest block of the network defined in `NODE_RPC`, with chainId 31337. These deployments use create3 deployer and it should be predeployed in original network or deploy it.
4. To deploy to a remote node, replace `[PUT_NETWORK_NAME_HERE]` with the correct UPPERCASE network name in `.env` and provide the correct values for the variables.
5. To deploy all contracts, use `make deploy-all`. It will automatically read the configuration from `.env` and deploy all contracts step by step. If any deployment fails, check the configuration and restart the process by running this command again. Check `Issues` section below for clarification.
6. To deploy a single contract, you can use the following commands:
    - `make deploy-helpers` deploys all helper contracts defined in `OPS_HELPER_NAMES` (pipe-separated list),
    - `make deploy-leftover-exchanger` deploys LeftoverExchanger,
    - `make deploy-fee-collector-factory` deploys FeeCollector and FeeCollectorFactory,
    - `make deploy-new-fee-collector` deploys specific FeeCollectors defined in `OPS_FEE_COLLECTOR_OPERATORS` and `OPS_FEE_COLLECTOR_OPERATORS_TARGETS`,
    - `make upgrade-fee-collector` upgrades the FeeCollector implementation.


## ENVIRONMENT VARIABLES

The following environment variables are used throughout the Makefile:
- OPS_NETWORK: The name of the network to deploy to (e.g., localhost).
- OPS_CHAIN_ID: The chain ID of the network.
- OPS_HELPER_NAMES: A pipe-separated list of helper contract names to deploy.
- OPS_UNIV4HELPER_ARGS: Arguments for the UniV4Helper contract.
- OPS_WETH_ADDRESS: The address of the WETH contract.
- OPS_CREATE3_DEPLOYER_ADDRESS: The address of the Create3 Deployer contract.
- OPS_LOP_ADDRESS: The address of the LOP contract.
- OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS: The owner address for the Fee Collector Factory.
- OPS_FEE_COLLECTOR_OWNER_ADDRESS: The owner address for the Fee Collector.
- OPS_ZKSYNC_MODE: A boolean indicating if ZKSync mode is enabled.
- OPS_FEE_COLLECTOR_OPERATORS: A JSON object mapping operator names to their addresses.
- OPS_FEE_COLLECTOR_OPERATORS_TARGETS: A pipe-separated list of operator targets.
- OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS: The owner address for the LeftoverExchanger.

### Example of .env file for local network:

```env
NODE_RPC=https://eth.drpc.org
OPS_NETWORK=localhost
OPS_CHAIN_ID=31337
OPS_HELPER_NAMES=UniV4Helper|EvmHelpers|KyberHelper
OPS_UNIV4HELPER_ARGS=["0x000000000004444c5dc75cB358380D2e3dE08A90", "0x7ffe42c4a5deea5b0fec41c94c136cf115597227", "0xbd216513d74c8cf14cf4747e6aaa6420ff64ee9e"]
OPS_WETH_ADDRESS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
OPS_CREATE3_DEPLOYER_ADDRESS="0x62f4807082fa27E711784C53fE5CBF056E6C11B2"
OPS_LOP_ADDRESS="0x111111125421cA6dc452d289314280a0f8842A65"
OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
OPS_FEE_COLLECTOR_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
OPS_ZKSYNC_MODE=false
OPS_FEE_COLLECTOR_OPERATORS={Safe: "0x0829b195d2d53887cd2316c0acb390ef8fecaef9", DevPortal: "0xA98F85F55F259ef41548251c93409F1D60e804e4"}
OPS_FEE_COLLECTOR_OPERATORS_TARGETS=Safe|DevPortal
OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
```

### Example of .env file for mainnet:

```env
MAINNET_RPC_URL=https://eth.drpc.org
MAINNET_PRIVATE_KEY=<your private key here>
MAINNET_ETHERSCAN_KEY=<your etherscan key here>
OPS_NETWORK=mainnet
OPS_CHAIN_ID=1
OPS_HELPER_NAMES=UniV4Helper|EvmHelpers|KyberHelper
OPS_UNIV4HELPER_ARGS=["0x000000000004444c5dc75cB358380D2e3dE08A90", "0x7ffe42c4a5deea5b0fec41c94c136cf115597227", "0xbd216513d74c8cf14cf4747e6aaa6420ff64ee9e"]
OPS_WETH_ADDRESS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
OPS_CREATE3_DEPLOYER_ADDRESS="0x62f4807082fa27E711784C53fE5CBF056E6C11B2"
OPS_LOP_ADDRESS="0x111111125421cA6dc452d289314280a0f8842A65"
OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
OPS_FEE_COLLECTOR_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
OPS_ZKSYNC_MODE=false
OPS_FEE_COLLECTOR_OPERATORS={Safe: "0x0829b195d2d53887cd2316c0acb390ef8fecaef9", DevPortal: "0xA98F85F55F259ef41548251c93409F1D60e804e4"}
OPS_FEE_COLLECTOR_OPERATORS_TARGETS=Safe|DevPortal
OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
```

## MAKEFILE TARGETS

Here is a list of Makefile targets you can use by running `make <target-name>` in the terminal:
- install-utils: Installs necessary utilities like yarn and wget.
- install-dependencies: Installs project dependencies using yarn.
- clean: Cleans up deployment files for the specified network.
- deploy-all: Deploys all necessary contracts for the specified network, ensuring all required environment variables are set.
- deploy-helpers: Deploys helper contracts based on the specified helper names.
- deploy-helpers-impl: Deploys each helper contract specified in OPS_HELPER_NAMES.
- deploy-leftover-exchanger: Deploys the LeftoverExchanger contract.
- deploy-leftover-exchanger-impl: Deploys the LeftoverExchanger contract.
- deploy-fee-collector-factory: Deploys the FeeCollectorFactory contract, with different implementations for ZKSync mode.
- deploy-fee-collector-factory-impl: Deploys the FeeCollectorFactory contract and updates its address in the constants file.
- deploy-new-fee-collector: Deploys new FeeCollector contracts for specified operators.
- deploy-new-fee-collector-impl: Deploys new FeeCollector contracts for each operator specified in OPS_FEE_COLLECTOR_OPERATORS_TARGETS.
- upgrade-fee-collector: Upgrades the FeeCollector contract, with different implementations for ZKSync mode.
- upgrade-fee-collector-impl: Upgrades the FeeCollector contract and updates its address in the constants file.
- process-helpers-args: Processes UniV4Helper arguments if specified.
- process-weth: Updates the WETH address in the constants file.
- process-create3-deployer: Updates the Create3 deployer address in the constants file.
- process-lop: Updates the LOP address in the constants file.
- process-fee-collector-factory-owner: Updates the FeeCollectorFactory owner address in the constants file.
- process-fee-collector-owner: Updates the FeeCollector owner address in the constants file.
- process-fee-collector-operator: Updates the FeeCollector operator addresses in the constants file.
- process-leftover-exchanger-owner: Updates the LeftoverExchanger owner address in the constants file.
- upsert-constant: Inserts or updates a constant in the specified file based on the chain ID.
- deploy-skip-all: Skips deployment for all specified deployment files.
- deploy-skip: Skips deployment for the current deployment file.
- deploy-noskip: Ensures deployment is not skipped for the current deployment file.
- launch-hh-node: Launches a Hardhat node with the specified RPC URL.
- git-latest-tag: Retrieves the latest Git tag.
- git-checkout: Creates a new Git branch for the specified network.
- git-push: Adds, commits, and pushes changes to the remote repository for the specified network.
- env-example: Generates an example `.env.example` file with placeholders for network configuration.

## ISSUES

- In case when the pipeline was broken and you are going to launch single target deployment first of all set all deployments skipable by calling `make deploy-skip-all`.
- Be careful with using `make clean` - it's remove all deployments in `./deployments/($OPS_NETWORK)`

## TODO 

- logging
- error handling
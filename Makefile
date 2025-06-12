-include .env

CURRENT_DIR=$(shell pwd)

FILE_DEPLOY=$(CURRENT_DIR)/deploy/deploy.js
FILE_DEPLOY_LEFTOVER_EXCHANGER=$(CURRENT_DIR)/deploy/deploy-leftover-exchanger.js
FILE_DEPLOY_FEE_COLLECTOR_FACTORY=$(CURRENT_DIR)/deploy/deploy-fee-collector-factory.js
FILE_DEPLOY_FEE_COLLECTOR_FACTORY_ZKSYNC=$(CURRENT_DIR)/deploy/deploy-fee-collector-factory-zksync.js
FILE_DEPLOY_NEW_FEE_COLLECTOR=$(CURRENT_DIR)/deploy/deploy-new-fee-collector.js
FILE_UPGRADE_FEE_COLLECTOR=$(CURRENT_DIR)/deploy/upgrade-fee-collector.js
FILE_UPGRADE_FEE_COLLECTOR_ZKSYNC=$(CURRENT_DIR)/deploy/upgrade-fee-collector-zksync.js

FILE_UNIV4_ARGS=$(CURRENT_DIR)/deploy/constants/uni-v4-helper-args.js
FILE_WETH=$(CURRENT_DIR)/deploy/constants/weth.js
FILE_CREATE3_DEPLOYER=$(CURRENT_DIR)/deploy/constants/create3-deployer.js
FILE_LOP=$(CURRENT_DIR)/deploy/constants/lop.js
FILE_FEE_COLLECTOR_FACTORY_OWNER=$(CURRENT_DIR)/deploy/constants/fee-collector-factory-owner.js
FILE_FEE_COLLECTOR_OWNER=$(CURRENT_DIR)/deploy/constants/fee-collector-owner.js
FILE_FEE_COLLECTOR_FACTORY=$(CURRENT_DIR)/deploy/constants/fee-collector-factory.js
FILE_FEE_COLLECTOR_OPERATOR=$(CURRENT_DIR)/deploy/constants/fee-collector-operator.js
FILE_LEFTOVER_EXCHANGER_OWNER=$(CURRENT_DIR)/deploy/constants/leftover-exchanger-owner.js

install: install-utils install-dependencies

install-utils:
			brew install yarn wget

install-dependencies:
			yarn install

clean:
		@rm -Rf $(CURRENT_DIR)/deployments/$(OPS_NETWORK)/*

deploy-all:
		@{ \
		if [ -z "$(OPS_NETWORK)" ]; then \
			echo "OPS_NETWORK is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_CHAIN_ID)" ]; then \
			echo "OPS_CHAIN_ID is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_HELPER_NAMES)" ]; then \
			echo "OPS_HELPER_NAMES is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_UNIV4HELPER_ARGS)" ]; then \
			echo "OPS_UNIV4HELPER_ARGS is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_WETH_ADDRESS)" ]; then \
			echo "OPS_WETH_ADDRESS is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_CREATE3_DEPLOYER_ADDRESS)" ]; then \
			echo "OPS_CREATE3_DEPLOYER_ADDRESS is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_LOP_ADDRESS)" ]; then \
			echo "OPS_LOP_ADDRESS is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS)" ]; then \
			echo "OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_OWNER_ADDRESS)" ]; then \
			echo "OPS_FEE_COLLECTOR_OWNER_ADDRESS is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_ZKSYNC_MODE)" ]; then \
			echo "OPS_ZKSYNC_MODE is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_OPERATORS)" ]; then \
			echo "OPS_FEE_COLLECTOR_OPERATORS is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_OPERATORS_TARGETS)" ]; then \
			echo "OPS_FEE_COLLECTOR_OPERATORS_TARGETS is not set!"; \
			exit 1; \
		fi; \
		echo "Deploying $(OPS_NETWORK) network..."; \
		echo "Chain ID: $(OPS_CHAIN_ID)"; \
		echo "Helpers: $(OPS_HELPER_NAMES)"; \
		echo "UniV4Helper args: $(OPS_UNIV4HELPER_ARGS)"; \
		echo "WETH address: $(OPS_WETH_ADDRESS)"; \
		echo "Create3 Deployer address: $(OPS_CREATE3_DEPLOYER_ADDRESS)"; \
		echo "Lop address: $(OPS_LOP_ADDRESS)"; \
		echo "Fee Collector Factory Owner address: $(OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS)"; \
		echo "Fee Collector Owner address: $(OPS_FEE_COLLECTOR_OWNER_ADDRESS)"; \
		echo "Fee Collector Operators: $(OPS_FEE_COLLECTOR_OPERATORS)"; \
		echo "Fee Collector Operators Targets: $(OPS_FEE_COLLECTOR_OPERATORS_TARGETS)"; \
		echo "ZKSync mode: $(OPS_ZKSYNC_MODE)"; \
		$(MAKE) deploy-skip-all deploy-helpers deploy-leftover-exchanger deploy-fee-collector-factory deploy-new-fee-collector; \
		}

deploy-helpers: 
		$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY) process-helpers-args deploy-noskip deploy-helpers-impl deploy-skip

deploy-helpers-impl:
		@{ \
		echo "$(OPS_HELPER_NAMES)" | tr "|" "\n"; \
		for secret in $$(echo "$(OPS_HELPER_NAMES)" | tr "|" "\n"); do \
			CONTRACT_HELPER_NAME=$$(echo "$$secret") yarn deploy $(OPS_NETWORK) || exit 1; \
		done \
		}

deploy-leftover-exchanger:
		$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_LEFTOVER_EXCHANGER) process-weth process-create3-deployer process-leftover-exchanger-owner deploy-noskip deploy-leftover-exchanger-impl deploy-skip

deploy-leftover-exchanger-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) || exit 1; \
		}

deploy-fee-collector-factory:
		@{ \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY_ZKSYNC) process-weth process-create3-deployer process-lop process-fee-collector-owner process-fee-collector-factory-owner deploy-noskip deploy-fee-collector-factory-impl deploy-skip; \
		else \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY) process-weth process-lop process-fee-collector-owner process-fee-collector-factory-owner deploy-noskip deploy-fee-collector-factory-impl deploy-skip; \
		fi \
		}

deploy-fee-collector-factory-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) > tmp || exit 1; \
		if grep -q "FeeCollectorFactory" tmp; then \
			echo "FeeCollectorFactory deployed successfully!"; \
			OPS_FEE_COLLECTOR_FACTORY_ADDRESS=$$(grep 'FeeCollectorFactory' tmp | grep -Eo '0x[a-fA-F0-9]{40}'); \
			$(MAKE) OPS_GEN_VAL=\"$$OPS_FEE_COLLECTOR_FACTORY_ADDRESS\" OPS_GEN_FILE=$(FILE_FEE_COLLECTOR_FACTORY) upsert-constant; \
			rm -f tmp; \
		else \
			echo "FeeCollectorFactory deployment failed!"; \
			rm -f tmp; \
			exit 1; \
		fi; \
		}

deploy-new-fee-collector:
		$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_NEW_FEE_COLLECTOR) process-fee-collector-operator deploy-noskip deploy-new-fee-collector-impl deploy-skip

deploy-new-fee-collector-impl:
		@{ \
		echo "$(OPS_FEE_COLLECTOR_OPERATORS_TARGETS)" | tr "|" "\n"; \
		for secret in $$(echo "$(OPS_FEE_COLLECTOR_OPERATORS_TARGETS)" | tr "|" "\n"); do \
			FEE_COLLECTOR_OPERATOR_NAME=$$(echo "$$secret") yarn deploy $(OPS_NETWORK) || exit 1; \
		done \
		}

upgrade-fee-collector:
		@{ \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_UPGRADE_FEE_COLLECTOR_ZKSYNC) process-weth process-create3-deployer process-lop process-fee-collector-owner deploy-noskip upgrade-fee-collector-impl deploy-skip; \
		else \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_UPGRADE_FEE_COLLECTOR) process-weth process-lop process-fee-collector-owner deploy-noskip upgrade-fee-collector-impl deploy-skip; \
		fi \
		}

upgrade-fee-collector-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) > tmp || exit 1; \
		}


process-helpers-args:
		@{ \
		if echo "$(OPS_HELPER_NAMES)" | grep -q "UniV4Helper"; then \
			$(MAKE) OPS_GEN_VAL='$(OPS_UNIV4HELPER_ARGS)' OPS_GEN_FILE=$(FILE_UNIV4_ARGS) upsert-constant; \
		fi \
		}

process-weth:
		@$(MAKE) OPS_GEN_VAL='$(OPS_WETH_ADDRESS)' OPS_GEN_FILE=$(FILE_WETH) upsert-constant

process-create3-deployer:
		@$(MAKE) OPS_GEN_VAL='$(OPS_CREATE3_DEPLOYER_ADDRESS)' OPS_GEN_FILE=$(FILE_CREATE3_DEPLOYER) upsert-constant

process-lop:
		@$(MAKE) OPS_GEN_VAL='$(OPS_LOP_ADDRESS)' OPS_GEN_FILE=$(FILE_LOP) upsert-constant

process-fee-collector-factory-owner:
		@$(MAKE) OPS_GEN_VAL='$(OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS)' OPS_GEN_FILE=$(FILE_FEE_COLLECTOR_FACTORY_OWNER) upsert-constant

process-fee-collector-owner:
		@$(MAKE) OPS_GEN_VAL='$(OPS_FEE_COLLECTOR_OWNER_ADDRESS)' OPS_GEN_FILE=$(FILE_FEE_COLLECTOR_OWNER) upsert-constant

process-fee-collector-operator:
		@$(MAKE) OPS_GEN_VAL='$(OPS_FEE_COLLECTOR_OPERATORS)' OPS_GEN_FILE=$(FILE_FEE_COLLECTOR_OPERATOR) upsert-constant

process-leftover-exchanger-owner:
		@$(MAKE) OPS_GEN_VAL='$(OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS)' OPS_GEN_FILE=$(FILE_LEFTOVER_EXCHANGER_OWNER) upsert-constant

upsert-constant:
		@{ \
		if [ -z "$(OPS_GEN_VAL)" ]; then \
			echo "variable for file $(OPS_GEN_FILE) is not set!"; \
			exit 1; \
		fi; \
		if grep -q "$(OPS_CHAIN_ID)" $(OPS_GEN_FILE); then \
			sed -i '' 's|$(OPS_CHAIN_ID): .*|$(OPS_CHAIN_ID): $(OPS_GEN_VAL),|' $(OPS_GEN_FILE); \
			sed -i '' 's/"/'\''/g' $(OPS_GEN_FILE); \
		else \
			awk '1;/module.exports = {/{print "    $(OPS_CHAIN_ID): $(subst ",\",$(OPS_GEN_VAL)),"}' $(OPS_GEN_FILE) > tmp && sed -i '' 's/"/'\''/g' tmp && mv tmp $(OPS_GEN_FILE); \
		fi \
		}

deploy-skip-all:
		@{ \
		for secret in $(FILE_DEPLOY) \
						$(FILE_DEPLOY_LEFTOVER_EXCHANGER) \
						$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY) \
						$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY_ZKSYNC) \
						$(FILE_DEPLOY_NEW_FEE_COLLECTOR) \
						$(FILE_UPGRADE_FEE_COLLECTOR) \
						$(FILE_UPGRADE_FEE_COLLECTOR_ZKSYNC); do \
			$(MAKE) OPS_CURRENT_DEP_FILE=$$secret deploy-skip; \
		done \
		}

deploy-skip:
		@sed -i '' 's/module.exports.skip.*/module.exports.skip = async () => true;/g' $(OPS_CURRENT_DEP_FILE)

deploy-noskip:
		@sed -i '' 's/module.exports.skip.*/module.exports.skip = async () => false;/g' $(OPS_CURRENT_DEP_FILE)

launch-hh-node:
		@{ \
		if [ -z "$(NODE_RPC)" ]; then \
			echo "NODE_RPC is not set!"; \
			exit 1; \
		fi; \
		echo "Launching Hardhat node with RPC: $(NODE_RPC)"; \
		npx hardhat node --fork $(NODE_RPC) --vvvv --full-trace; \
		}

git-latest-tag:
		@git describe --abbrev=0

git-checkout:
		@git checkout -b feature/$(OPS_NETWORK)

git-push:
		@git add .
		@git commit -m "added $(OPS_NETWORK) network"
		@git push origin feature/$(OPS_NETWORK)

env-example:
	@{ \
	echo '[PUT_NETWORK_NAME_HERE]_RPC_URL=' >> .env.example; \
	echo '[PUT_NETWORK_NAME_HERE]_PRIVATE_KEY=' >> .env.example; \
	echo '[PUT_NETWORK_NAME_HERE]_ETHERSCAN_KEY=' >> .env.example; \
	echo 'OPS_NETWORK=localhost' >> .env.example; \
	echo 'OPS_CHAIN_ID=31337' >> .env.example; \
	echo 'OPS_HELPER_NAMES=UniV4Helper|EvmHelpers|KyberHelper' >> .env.example; \
	echo 'OPS_UNIV4HELPER_ARGS=["0x000000000004444c5dc75cB358380D2e3dE08A90", "0x7ffe42c4a5deea5b0fec41c94c136cf115597227", "0xbd216513d74c8cf14cf4747e6aaa6420ff64ee9e"]' >> .env.example; \
	echo 'OPS_WETH_ADDRESS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"' >> .env.example; \
	echo 'OPS_CREATE3_DEPLOYER_ADDRESS="0x62f4807082fa27E711784C53fE5CBF056E6C11B2"' >> .env.example; \
	echo 'OPS_LOP_ADDRESS="0x111111125421cA6dc452d289314280a0f8842A65"' >> .env.example; \
	echo 'OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"' >> .env.example; \
	echo 'OPS_FEE_COLLECTOR_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"' >> .env.example; \
	echo 'OPS_ZKSYNC_MODE=false' >> .env.example; \
	echo 'OPS_FEE_COLLECTOR_OPERATORS={Safe: "0x0829b195d2d53887cd2316c0acb390ef8fecaef9", DevPortal: "0xA98F85F55F259ef41548251c93409F1D60e804e4"}' >> .env.example; \
	echo 'OPS_FEE_COLLECTOR_OPERATORS_TARGETS=Safe|DevPortal' >> .env.example; \
	echo 'OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"' >> .env.example; \
	}

.PHONY: install-utils install-dependencies clean deploy-all deploy-helpers deploy-helpers-impl deploy-leftover-exchanger deploy-leftover-exchanger-impl deploy-fee-collector-factory deploy-fee-collector-factory-impl deploy-new-fee-collector deploy-new-fee-collector-impl upgrade-fee-collector upgrade-fee-collector-impl process-helpers-args process-weth process-create3-deployer process-lop process-fee-collector-factory-owner process-fee-collector-owner process-fee-collector-operator process-leftover-exchanger-owner upsert-constant deploy-skip-all deploy-skip deploy-noskip launch-hh-node git-latest-tag git-checkout git-push env-example
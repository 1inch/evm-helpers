# Conditionally include .env or .env.automation based on OPS_LAUNCH_MODE
ifeq ($(OPS_LAUNCH_MODE),auto)
-include .env.automation
else
-include .env
endif
export

CURRENT_DIR=$(shell pwd)

OPS_NETWORK := $(subst ",,$(OPS_NETWORK))
OPS_CHAIN_ID := $(subst ",,$(OPS_CHAIN_ID))
OPS_ZKSYNC_MODE := $(subst ",,$(OPS_ZKSYNC_MODE))
OPS_DEPLOYMENT_METHOD := $(subst ",,$(OPS_DEPLOYMENT_METHOD))

ifeq ($(OPS_ZKSYNC_MODE),)
ifeq ($(OPS_CHAIN_ID),324)
	OPS_ZKSYNC_MODE=true
endif
endif

CURRENT_DIR:=$(shell pwd)

FILE_DEPLOY:=$(CURRENT_DIR)/deploy/deploy.js
FILE_DEPLOY_LEFTOVER_EXCHANGER:=$(CURRENT_DIR)/deploy/deploy-leftover-exchanger.js
FILE_DEPLOY_FEE_COLLECTOR_FACTORY:=$(CURRENT_DIR)/deploy/deploy-fee-collector-factory.js
FILE_DEPLOY_FEE_COLLECTOR_FACTORY_ZKSYNC:=$(CURRENT_DIR)/deploy/deploy-fee-collector-factory-zksync.js
FILE_DEPLOY_NEW_FEE_COLLECTOR:=$(CURRENT_DIR)/deploy/deploy-new-fee-collector.js
FILE_UPGRADE_FEE_COLLECTOR:=$(CURRENT_DIR)/deploy/upgrade-fee-collector.js
FILE_UPGRADE_FEE_COLLECTOR_ZKSYNC:=$(CURRENT_DIR)/deploy/upgrade-fee-collector-zksync.js

FILE_UNIV4_ARGS:=$(CURRENT_DIR)/deploy/constants/uni-v4-helper-args.js
FILE_WETH:=$(CURRENT_DIR)/deploy/constants/weth.js
FILE_CREATE3_DEPLOYER:=$(CURRENT_DIR)/deploy/constants/create3-deployer.js
FILE_LOP:=$(CURRENT_DIR)/deploy/constants/lop.js
FILE_FEE_COLLECTOR_FACTORY_OWNER:=$(CURRENT_DIR)/deploy/constants/fee-collector-factory-owner.js
FILE_FEE_COLLECTOR_OWNER:=$(CURRENT_DIR)/deploy/constants/fee-collector-owner.js
FILE_FEE_COLLECTOR_FACTORY:=$(CURRENT_DIR)/deploy/constants/fee-collector-factory.js
FILE_FEE_COLLECTOR_OPERATOR:=$(CURRENT_DIR)/deploy/constants/fee-collector-operator.js
FILE_LEFTOVER_EXCHANGER_OWNER:=$(CURRENT_DIR)/deploy/constants/leftover-exchanger-owner.js

deploy-all:
		$(MAKE) deploy-skip-all deploy-helpers deploy-leftover-exchanger deploy-fee-collector-factory deploy-new-fee-collector

deploy-helpers: 
		$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY) OPS_DEPLOYMENT_METHOD=$(if $(OPS_DEPLOYMENT_METHOD),$(OPS_DEPLOYMENT_METHOD),create3) deploy-skip-all validate-helpers deploy-noskip deploy-helpers-impl deploy-skip

deploy-helpers-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) || exit 1; \
		}

deploy-leftover-exchanger:
		$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_LEFTOVER_EXCHANGER) deploy-skip-all validate-leftover-exchanger deploy-noskip deploy-leftover-exchanger-impl deploy-skip

deploy-leftover-exchanger-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) || exit 1; \
		}

deploy-fee-collector-factory:
		@{ \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY_ZKSYNC) deploy-skip-all validate-fee-collector-factory deploy-noskip deploy-fee-collector-factory-impl deploy-skip; \
		else \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY) deploy-skip-all validate-fee-collector-factory deploy-noskip deploy-fee-collector-factory-impl deploy-skip; \
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
		$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_NEW_FEE_COLLECTOR) deploy-skip-all validate-new-fee-collector deploy-noskip deploy-new-fee-collector-impl deploy-skip

deploy-new-fee-collector-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) || exit 1;
		}

upgrade-fee-collector:
		@{ \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_UPGRADE_FEE_COLLECTOR_ZKSYNC) deploy-skip-all validate-upgrade-fee-collector deploy-noskip upgrade-fee-collector-impl deploy-skip; \
		else \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_UPGRADE_FEE_COLLECTOR) deploy-skip-all validate-upgrade-fee-collector deploy-noskip upgrade-fee-collector-impl deploy-skip; \
		fi \
		}

upgrade-fee-collector-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) > tmp || exit 1; \
		}

# Validation targets
validate-helpers:
		@{ \
		if [ -z "$(OPS_NETWORK)" ]; then echo "OPS_NETWORK is not set!"; exit 1; fi; \
		if [ -z "$(OPS_CHAIN_ID)" ]; then echo "OPS_CHAIN_ID is not set!"; exit 1; fi; \
		if [ -z "$(OPS_EVM_HELPER_NAMES)" ]; then echo "OPS_EVM_HELPER_NAMES is not set!"; exit 1; fi; \
		if [ -z "$(MAINNET_RPC_URL)" ] && [ "$(OPS_NETWORK)" = "hardhat" ]; then echo "MAINNET_RPC_URL is not set!"; exit 1; fi; \
		$(MAKE) process-helpers-args; \
		}

validate-leftover-exchanger:
		@{ \
		if [ -z "$(OPS_NETWORK)" ]; then echo "OPS_NETWORK is not set!"; exit 1; fi; \
		if [ -z "$(OPS_CHAIN_ID)" ]; then echo "OPS_CHAIN_ID is not set!"; exit 1; fi; \
		if [ -z "$(OPS_WETH_ADDRESS)" ]; then echo "OPS_WETH_ADDRESS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_CREATE3_DEPLOYER_ADDRESS)" ]; then echo "OPS_CREATE3_DEPLOYER_ADDRESS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS)" ]; then echo "OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS is not set!"; exit 1; fi; \
		$(MAKE) process-weth process-create3-deployer process-leftover-exchanger-owner; \
		}

validate-fee-collector-factory:
		@{ \
		if [ -z "$(OPS_NETWORK)" ]; then echo "OPS_NETWORK is not set!"; exit 1; fi; \
		if [ -z "$(OPS_CHAIN_ID)" ]; then echo "OPS_CHAIN_ID is not set!"; exit 1; fi; \
		if [ -z "$(OPS_WETH_ADDRESS)" ]; then echo "OPS_WETH_ADDRESS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_LOP_ADDRESS)" ]; then echo "OPS_LOP_ADDRESS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_OWNER_ADDRESS)" ]; then echo "OPS_FEE_COLLECTOR_OWNER_ADDRESS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS)" ]; then echo "OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS is not set!"; exit 1; fi; \
		if [ "$(OPS_ZKSYNC_MODE)" != "true" ] && [ -z "$(OPS_CREATE3_DEPLOYER_ADDRESS)" ]; then echo "OPS_CREATE3_DEPLOYER_ADDRESS is not set!"; exit 1; fi; \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) process-weth process-lop process-fee-collector-owner process-fee-collector-factory-owner; \
		else \
			$(MAKE) process-weth process-create3-deployer process-lop process-fee-collector-owner process-fee-collector-factory-owner; \
		fi \
		}

validate-new-fee-collector:
		@{ \
		if [ -z "$(OPS_NETWORK)" ]; then echo "OPS_NETWORK is not set!"; exit 1; fi; \
		if [ -z "$(OPS_CHAIN_ID)" ]; then echo "OPS_CHAIN_ID is not set!"; exit 1; fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_OPERATORS)" ]; then echo "OPS_FEE_COLLECTOR_OPERATORS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_OPERATOR_NAMES)" ]; then echo "OPS_FEE_COLLECTOR_OPERATOR_NAMES is not set!"; exit 1; fi; \
		$(MAKE) process-fee-collector-operator; \
		}

validate-upgrade-fee-collector:
		@{ \
		if [ -z "$(OPS_NETWORK)" ]; then echo "OPS_NETWORK is not set!"; exit 1; fi; \
		if [ -z "$(OPS_CHAIN_ID)" ]; then echo "OPS_CHAIN_ID is not set!"; exit 1; fi; \
		if [ -z "$(OPS_WETH_ADDRESS)" ]; then echo "OPS_WETH_ADDRESS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_LOP_ADDRESS)" ]; then echo "OPS_LOP_ADDRESS is not set!"; exit 1; fi; \
		if [ -z "$(OPS_FEE_COLLECTOR_OWNER_ADDRESS)" ]; then echo "OPS_FEE_COLLECTOR_OWNER_ADDRESS is not set!"; exit 1; fi; \
		if [ "$(OPS_ZKSYNC_MODE)" != "true" ] && [ -z "$(OPS_CREATE3_DEPLOYER_ADDRESS)" ]; then echo "OPS_CREATE3_DEPLOYER_ADDRESS is not set!"; exit 1; fi; \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) process-weth process-lop process-fee-collector-owner; \
		else \
			$(MAKE) process-weth process-create3-deployer process-lop process-fee-collector-owner; \
		fi \
		}


process-helpers-args:
		@{ \
		if echo "$(OPS_EVM_HELPER_NAMES)" | grep -q "UniV4Helper"; then \
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
			tmpfile=$$(mktemp); \
			awk '1;/module.exports = {/{print "    $(OPS_CHAIN_ID): $(subst ",\",$(OPS_GEN_VAL)),"}' $(OPS_GEN_FILE) > $$tmpfile && sed -i '' 's/"/'\''/g' $$tmpfile && mv $$tmpfile $(OPS_GEN_FILE); \
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

# Get deployed contract addresses from deployment files
get:
		@{ \
		if [ -z "$(PARAMETER)" ]; then \
			echo "Error: PARAMETER is not set. Usage: make get PARAMETER=OPS_RESOLVER_ADDRESS"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_NETWORK)" ]; then \
			echo "Error: OPS_NETWORK is not set"; \
			exit 1; \
		fi; \
		if [ ! -d "$(CURRENT_DIR)/deployments/$(OPS_NETWORK)" ]; then \
			echo "Error: Directory $(CURRENT_DIR)/deployments/$(OPS_NETWORK) does not exist"; \
			exit 1; \
		fi; \
		CONTRACT_FILE=""; \
		contracts_list=$$(ls $(CURRENT_DIR)/deployments/$(OPS_NETWORK)/*.json | xargs -n1 basename | sed 's/\.json$$//'); \
		found=0; \
		for contract in $$contracts_list; do \
			contract_upper=$$(echo $$contract | sed 's/\([A-Z]\)/_\1/g' | sed 's/^_//' | tr 'a-z' 'A-Z'); \
			if [ "$(PARAMETER)" = "OPS_$${contract_upper}_ADDRESS" ]; then \
				CONTRACT_FILE="$${contract}.json"; \
				found=1; \
				break; \
			fi; \
		done; \
		if [ "$$found" -eq 0 ]; then \
			echo "Error: Unknown parameter $(PARAMETER)"; exit 1; \
		fi; \
		DEPLOYMENT_FILE="$(CURRENT_DIR)/deployments/$(OPS_NETWORK)/$$CONTRACT_FILE"; \
		if [ ! -f "$$DEPLOYMENT_FILE" ]; then \
			echo "Error: Deployment file $$DEPLOYMENT_FILE not found"; \
			exit 1; \
		fi; \
		ADDRESS=$$(cat "$$DEPLOYMENT_FILE" | grep '"address"' | head -1 | sed 's/.*"address": *"\([^"]*\)".*/\1/'); \
		echo "$$ADDRESS"; \
		}

get-outputs:
		@{ \
		if [ -z "$(OPS_NETWORK)" ]; then \
			echo "Error: OPS_NETWORK is not set"; \
			exit 1; \
		fi; \
		if [ ! -d "$(CURRENT_DIR)/deployments/$(OPS_NETWORK)" ]; then \
			echo "Error: Directory $(CURRENT_DIR)/deployments/$(OPS_NETWORK) does not exist"; \
			exit 1; \
		fi; \
		result="{"; \
		first=1; \
		for file in $(CURRENT_DIR)/deployments/$(OPS_NETWORK)/*.json; do \
			filename=$$(basename $$file .json); \
			key="OPS_$$(echo $$filename | sed 's/\([A-Z]\)/_\1/g' | sed 's/^_//' | tr 'a-z' 'A-Z')_ADDRESS"; \
			if [ $$first -eq 1 ]; then \
				result="$$result\"$$key\": \"$$key\""; \
				first=0; \
			else \
				result="$$result, \"$$key\": \"$$key\""; \
			fi; \
		done; \
		result="$$result}"; \
		echo "$$result"; \
		}

launch-hh-node:
		@{ \
		if [ -z "$(NODE_RPC)" ]; then \
			echo "NODE_RPC is not set!"; \
			exit 1; \
		fi; \
		echo "Launching Hardhat node with RPC: $(NODE_RPC)"; \
		npx hardhat node --fork $(NODE_RPC) --vvvv --full-trace; \
		}

install: install-utils install-dependencies

install-utils:
			brew install yarn wget

install-dependencies:
			yarn install

clean:
		@rm -Rf $(CURRENT_DIR)/deployments/$(OPS_NETWORK)/*

help:
	@echo "Available targets:"
	@echo "  install                Install utils and dependencies"
	@echo "  install-utils          Install yarn and wget via brew"
	@echo "  install-dependencies   Install node dependencies via yarn"
	@echo "  clean                  Remove deployments for current network"
	@echo "  deploy-all             Deploy all contracts"
	@echo "  deploy-helpers         Deploy helper contracts"
	@echo "  deploy-leftover-exchanger Deploy leftover exchanger contract"
	@echo "  deploy-fee-collector-factory Deploy fee collector factory contract"
	@echo "  deploy-new-fee-collector Deploy new fee collector contract"
	@echo "  upgrade-fee-collector  Upgrade fee collector contract"
	@echo "  get PARAMETER=...      Get deployed contract address"
	@echo "  launch-hh-node         Launch Hardhat node with forked RPC"
	@echo "  help                   Show this help message"

.PHONY: install install-utils install-dependencies clean deploy-all deploy-helpers deploy-helpers-impl deploy-leftover-exchanger deploy-leftover-exchanger-impl deploy-fee-collector-factory deploy-fee-collector-factory-impl deploy-new-fee-collector deploy-new-fee-collector-impl upgrade-fee-collector upgrade-fee-collector-impl validate-helpers validate-leftover-exchanger validate-fee-collector-factory validate-new-fee-collector validate-upgrade-fee-collector process-helpers-args process-weth process-create3-deployer process-lop process-fee-collector-factory-owner process-fee-collector-owner process-fee-collector-operator process-leftover-exchanger-owner upsert-constant deploy-skip-all deploy-skip deploy-noskip get launch-hh-node help

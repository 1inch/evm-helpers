# Conditionally include .env or .env.automation based on OPS_LAUNCH_MODE
ifeq ($(OPS_LAUNCH_MODE),auto)
-include .env.automation
else
-include .env
endif
export

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

FILE_CONSTANTS_JSON:=$(CURRENT_DIR)/config/constants.json

deploy-all:
		@$(MAKE) deploy-skip-all deploy-helpers deploy-leftover-exchanger deploy-fee-collector-factory deploy-new-fee-collector

deploy-helpers: 
		@$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY) OPS_DEPLOYMENT_METHOD=$(if $(OPS_DEPLOYMENT_METHOD),$(OPS_DEPLOYMENT_METHOD),create3) deploy-skip-all validate-helpers deploy-noskip deploy-impl deploy-skip

deploy-impl:
		@{ \
		yarn deploy $(OPS_NETWORK) || exit 1; \
		}

deploy-leftover-exchanger:
		@$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_LEFTOVER_EXCHANGER) deploy-skip-all validate-leftover-exchanger deploy-noskip deploy-impl deploy-skip

deploy-fee-collector-factory:
		@{ \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY_ZKSYNC) deploy-skip-all validate-fee-collector-factory deploy-noskip deploy-impl deploy-skip; \
		else \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_FEE_COLLECTOR_FACTORY) deploy-skip-all validate-fee-collector-factory deploy-noskip deploy-impl deploy-skip; \
		fi \
		}

deploy-new-fee-collector:
		@$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_DEPLOY_NEW_FEE_COLLECTOR) deploy-skip-all validate-new-fee-collector deploy-noskip deploy-impl deploy-skip

upgrade-fee-collector:
		@{ \
		if [ "$(OPS_ZKSYNC_MODE)" = "true" ]; then \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_UPGRADE_FEE_COLLECTOR_ZKSYNC) deploy-skip-all validate-upgrade-fee-collector deploy-noskip deploy-impl deploy-skip; \
		else \
			$(MAKE) OPS_CURRENT_DEP_FILE=$(FILE_UPGRADE_FEE_COLLECTOR) deploy-skip-all validate-upgrade-fee-collector deploy-noskip deploy-impl deploy-skip; \
		fi \
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
		if [ -z "$(OPS_LEFTOVER_EXCHANGER_SALT)" ] && [ "$(OPS_DEPLOYMENT_METHOD)" = "create3" ] && [ "$(OPS_CHAIN_ID)" != "324" ]; then echo "OPS_LEFTOVER_EXCHANGER_SALT is not set!"; exit 1; fi; \
		$(MAKE) process-weth process-create3-deployer process-leftover-exchanger-owner process-leftover-exchanger-salt; \
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
			$(MAKE) OPS_GEN_KEY=constructorArgs.UniV4Helper OPS_GEN_VAL='$(OPS_UNIV4HELPER_ARGS)' upsert-constant; \
		fi \
		}

process-weth:
		@$(MAKE) OPS_GEN_KEY=weth OPS_GEN_VAL='$(OPS_WETH_ADDRESS)' upsert-constant

process-create3-deployer:
		@$(MAKE) OPS_GEN_KEY=create3DeployerContract OPS_GEN_VAL='$(OPS_CREATE3_DEPLOYER_ADDRESS)' upsert-constant

process-lop:
		@$(MAKE) OPS_GEN_KEY=lop OPS_GEN_VAL='$(OPS_LOP_ADDRESS)' upsert-constant

process-fee-collector-factory-owner:
		@$(MAKE) OPS_GEN_KEY=feeCollectorFactoryOwner OPS_GEN_VAL='$(OPS_FEE_COLLECTOR_FACTORY_OWNER_ADDRESS)' upsert-constant

process-fee-collector-owner:
		@$(MAKE) OPS_GEN_KEY=feeCollectorOwner OPS_GEN_VAL='$(OPS_FEE_COLLECTOR_OWNER_ADDRESS)' upsert-constant

process-fee-collector-operator:
		@$(MAKE) OPS_GEN_KEY=feeCollectorOperator OPS_GEN_VAL='$(OPS_FEE_COLLECTOR_OPERATORS)' upsert-constant

process-leftover-exchanger-owner:
		@$(MAKE) OPS_GEN_KEY=leftoverExchangerOwner OPS_GEN_VAL='$(OPS_LEFTOVER_EXCHANGER_OWNER_ADDRESS)' upsert-constant

process-leftover-exchanger-salt:
		@$(MAKE) OPS_GEN_KEY=leftoverExchangerSalt OPS_GEN_VAL='$(OPS_LEFTOVER_EXCHANGER_SALT)' upsert-constant

upsert-constant:
		@{ \
		if [ -z "$(OPS_GEN_VAL)" ]; then \
			echo "Variable for key $(OPS_GEN_KEY) is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_GEN_KEY)" ]; then \
			echo "OPS_GEN_KEY is not set!"; \
			exit 1; \
		fi; \
		if [ -z "$(OPS_CHAIN_ID)" ]; then \
			echo "OPS_CHAIN_ID is not set!"; \
			exit 1; \
		fi; \
		tmpfile=$$(mktemp); \
		jq '.$(OPS_GEN_KEY)."$(OPS_CHAIN_ID)" = $(OPS_GEN_VAL)' $(FILE_CONSTANTS_JSON) > $$tmpfile && mv $$tmpfile $(FILE_CONSTANTS_JSON); \
		echo "Updated $(OPS_GEN_KEY)[$(OPS_CHAIN_ID)] = $(OPS_GEN_VAL)"; \
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

install: install-utils install-dependencies

install-utils:
			brew install yarn wget jq

install-dependencies:
			yarn

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

.PHONY: install install-utils install-dependencies clean deploy-all deploy-helpers deploy-leftover-exchanger deploy-fee-collector-factory deploy-new-fee-collector upgrade-fee-collector get get-outputs help
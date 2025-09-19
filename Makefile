# ParityTax-AMM Makefile
# Deployment and development commands for ParityTax-AMM project

.PHONY: help build test deploy-fiscal-log-dispatcher deploy-liquidity-resolvers deploy-fiscal-policy deploy-all clean

# Default target
help:
	@echo "ParityTax-AMM Development Commands"
	@echo "=================================="
	@echo "build                    - Build the project"
	@echo "test                     - Run tests"
	@echo "deploy-fiscal-log-dispatcher - Deploy FiscalLogDispatcher library to Reactive Testnet"
	@echo "deploy-liquidity-resolvers - Deploy liquidity resolvers to Sepolia"
	@echo "deploy-fiscal-policy     - Deploy fiscal policy to Sepolia"
	@echo "deploy-all              - Deploy all contracts to Sepolia"
	@echo "clean                   - Clean build artifacts"

# Build the project
build:
	forge build

# Run tests
test:
	forge test


deploy-lp-oracle:
	forge script script/DeployLPOracle.s.sol:DeployLPOracleScript \
		--broadcast --rpc-url sepolia --verify
	
deploy-fiscal-log-dispatcher:
	forge create --broadcast --rpc-url reactive-testnet --private-key $$PRIVATE_KEY --chain-id 5318007 src/libraries/FiscalLogDispatcher.sol:FiscalLogDispatcher

deploy-parity-tax-hook:
	forge script script/DeployParityTaxHook.s.sol:DeployParityTaxHookScript \
		--sig "run(address,address,address)" \
		0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
		0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4 \
		0x2f1AE40ca3a236c50B39Db42BCCbBb525063253e \
		--broadcast --rpc-url sepolia --verify

# Deploy Liquidity Resolvers to Sepolia
deploy-liquidity-resolvers:
	forge script script/DeployLiquidityResolvers.s.sol:DeployLiquidityResolversScript \
		--sig "run(address,address,address)" \
		0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
		0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4 \
		0x468947142AEf4F380b5E0794B5c2296faa6d6Fd3 \
		--broadcast --rpc-url sepolia --verify

# Deploy Fiscal Policy to Sepolia
deploy-fiscal-policy:
	forge script script/DeployFiscalPolicy.s.sol:DeployFiscalPolicyScript \
		--sig "run(address,address,address,address,address,address)" \
		0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA \
		0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
		0x2f1AE40ca3a236c50B39Db42BCCbBb525063253e \
		0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4 \
		0x468947142AEf4F380b5E0794B5c2296faa6d6Fd3 \
		0x61b3f2011a92d183c7dbadbda940a7555ccf9227 \
		--broadcast --rpc-url sepolia --verify

# Deploy all contracts (run both deployment scripts)
deploy-all: deploy-lp-oracle deploy-parity-tax-hook deploy-liquidity-resolvers deploy-fiscal-policy
	@echo "All contracts deployed successfully!"

# Clean build artifacts
clean:
	forge clean

# Additional useful commands
install:
	forge install

# Run specific test file
test-hook:
	forge test --match-path test/ParityTaxTest.t.sol

# Run tests with gas reporting
test-gas:
	forge test --match-path test/ParityTaxTest.t.sol --gas-report

# Check for linting issues
lint:
	forge build --sizes

# Format code
format:
	forge fmt

# Show contract sizes
sizes:
	forge build --sizes

# Compile LaTeX presentation with traditional BibTeX
presentation:
	cd docs && pdflatex presentation.tex
	cd docs && bibtex presentation
	cd docs && pdflatex presentation.tex
	cd docs && pdflatex presentation.tex  # Run twice for proper references

# Clean LaTeX build artifacts
clean-presentation:
	cd docs && rm -f *.aux *.log *.nav *.out *.snm *.toc *.vrb *.fls *.fdb_latexmk *.bbl *.bcf *.blg *.run.xml

# View presentation (requires pdf viewer)
view-presentation: presentation
	cd docs && xdg-open presentation.pdf 2>/dev/null || open presentation.pdf 2>/dev/null || echo "Please open docs/presentation.pdf manually"
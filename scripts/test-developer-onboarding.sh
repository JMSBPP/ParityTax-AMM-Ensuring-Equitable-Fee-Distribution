#!/bin/bash

# Developer Onboarding Test Script
# This script simulates a fresh developer cloning and building the project

set -e  # Exit on any error

echo "🚀 Testing Developer Onboarding Process"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a clean state
print_status "Checking current environment..."

# Step 1: Clean everything
print_status "Step 1: Cleaning existing build artifacts..."
make clean 2>/dev/null || true
rm -rf out/ 2>/dev/null || true
rm -rf cache/ 2>/dev/null || true
print_success "Clean completed"

# Step 2: Check dependencies
print_status "Step 2: Checking system dependencies..."

# Check if foundry is installed
if ! command -v forge &> /dev/null; then
    print_error "Foundry is not installed. Please install Foundry first:"
    echo "curl -L https://foundry.paradigm.xyz | bash"
    echo "foundryup"
    exit 1
fi

# Check foundry version
FORGE_VERSION=$(forge --version | head -n1)
print_success "Foundry installed: $FORGE_VERSION"

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed"
    exit 1
fi
print_success "Git is available"

# Step 3: Simulate fresh clone (if not already in project)
if [ ! -f "foundry.toml" ]; then
    print_status "Step 3: Simulating fresh clone..."
    print_warning "This script should be run from within the project directory"
    print_warning "For a true fresh test, clone the repo in a separate directory:"
    echo "git clone <your-repo-url> test-clone"
    echo "cd test-clone"
    echo "chmod +x scripts/test-developer-onboarding.sh"
    echo "./scripts/test-developer-onboarding.sh"
    exit 1
fi

print_success "Project directory detected"

# Step 4: Install dependencies
print_status "Step 4: Installing dependencies..."
forge install --no-commit
print_success "Dependencies installed"

# Step 5: Build the project
print_status "Step 5: Building the project..."
forge build
print_success "Build completed successfully"

# Step 6: Run tests
print_status "Step 6: Running tests..."
forge test
print_success "All tests passed"

# Step 7: Check for common issues
print_status "Step 7: Checking for common issues..."

# Check for missing files
MISSING_FILES=()
if [ ! -f "src/ParityTaxHook.sol" ]; then
    MISSING_FILES+=("src/ParityTaxHook.sol")
fi
if [ ! -f "test/ParityTaxTest.t.sol" ]; then
    MISSING_FILES+=("test/ParityTaxTest.t.sol")
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    print_error "Missing critical files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    exit 1
fi

print_success "All critical files present"

# Step 8: Test deployment scripts
print_status "Step 8: Testing deployment scripts..."
if [ -f "script/DeployParityTaxHook.s.sol" ]; then
    forge script script/DeployParityTaxHook.s.sol --dry-run
    print_success "Deployment script validation passed"
else
    print_warning "Deployment script not found"
fi

# Step 9: Check documentation
print_status "Step 9: Checking documentation..."
if [ -f "README.md" ]; then
    print_success "README.md present"
else
    print_warning "README.md missing"
fi

if [ -f "docs/architecture-overview.md" ]; then
    print_success "Architecture documentation present"
else
    print_warning "Architecture documentation missing"
fi

# Step 10: Final summary
echo ""
echo "🎉 Developer Onboarding Test Complete!"
echo "======================================"
print_success "✅ Project builds successfully"
print_success "✅ All tests pass"
print_success "✅ Dependencies installed correctly"
print_success "✅ Critical files present"
print_success "✅ Ready for development"

echo ""
echo "📋 Next Steps for New Developers:"
echo "1. Read README.md for project overview"
echo "2. Review docs/architecture-overview.md for technical details"
echo "3. Run 'make help' to see available commands"
echo "4. Start with 'make test' to run the test suite"
echo "5. Check out the deployed contracts in README.md"

echo ""
echo "🔧 Available Commands:"
echo "- make build     : Build the project"
echo "- make test      : Run all tests"
echo "- make test-gas  : Run tests with gas reporting"
echo "- make deploy-*  : Deploy contracts to testnet"
echo "- make clean     : Clean build artifacts"
echo "- make format    : Format Solidity code"
echo "- make sizes     : Show contract sizes"

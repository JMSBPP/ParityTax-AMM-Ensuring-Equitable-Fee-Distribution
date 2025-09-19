# Developer Onboarding Checklist

This checklist helps ensure that new developers can successfully clone, build, and contribute to the ParityTax-AMM project.

## Prerequisites

- [ ] **Foundry installed** (latest version)
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
- [ ] **Git installed** and configured
- [ ] **Node.js** (for any JavaScript tooling)
- [ ] **Docker** (optional, for containerized testing)

## Fresh Clone Test

### Step 1: Clone the Repository
```bash
git clone https://github.com/JMSBPP/ParityTax-AMM-Ensuring-Equitable-Fee-Distribution.git
cd ParityTax-AMM-Ensuring-Equitable-Fee-Distribution
```

### Step 2: Install Dependencies
```bash
forge install --no-commit
```

### Step 3: Build the Project
```bash
forge build
# or
make build
```

### Step 4: Run Tests
```bash
forge test
# or
make test
```

### Step 5: Verify Documentation
- [ ] README.md is present and readable
- [ ] Architecture documentation exists
- [ ] Setup instructions are clear
- [ ] Deployed contract addresses are current

## Automated Testing

### Run the Onboarding Test Script
```bash
chmod +x scripts/test-developer-onboarding.sh
./scripts/test-developer-onboarding.sh
```

### Test with Docker (Isolated Environment)
```bash
docker build -f Dockerfile.test -t paritytax-test .
docker run --rm paritytax-test forge test
```

## Common Issues and Solutions

### Issue: "forge: command not found"
**Solution**: Install Foundry
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Issue: "Permission denied" on scripts
**Solution**: Make scripts executable
```bash
chmod +x scripts/*.sh
```

### Issue: "Dependencies not found"
**Solution**: Install dependencies
```bash
forge install --no-commit
```

### Issue: "Tests failing"
**Solution**: Check for missing environment variables or configuration

### Issue: "Build errors"
**Solution**: 
1. Check Solidity version compatibility
2. Verify all dependencies are installed
3. Check for missing files

## Verification Steps

After successful setup, verify:

- [ ] **Build Success**: `forge build` completes without errors
- [ ] **Tests Pass**: `forge test` shows all tests passing
- [ ] **Documentation**: Can access and understand project documentation
- [ ] **Deployment**: Can run deployment scripts (dry-run)
- [ ] **Code Quality**: Code formatting and linting work

## Development Workflow

### Daily Development
1. **Pull latest changes**: `git pull origin main`
2. **Build project**: `make build`
3. **Run tests**: `make test`
4. **Make changes**: Edit code as needed
5. **Test changes**: `make test`
6. **Format code**: `make format`
7. **Commit changes**: `git add . && git commit -m "description"`

### Before Contributing
1. **Run full test suite**: `make test`
2. **Check code formatting**: `make format`
3. **Verify build**: `make build`
4. **Update documentation** if needed
5. **Create pull request**

## Troubleshooting

### Reset to Clean State
```bash
make clean
forge install --no-commit
forge build
forge test
```

### Check System Requirements
```bash
forge --version
git --version
node --version  # if using JS tools
```

### Verify Project Structure
```bash
ls -la src/          # Should contain main contracts
ls -la test/         # Should contain test files
ls -la script/       # Should contain deployment scripts
ls -la docs/         # Should contain documentation
```

## Getting Help

If you encounter issues:

1. **Check this checklist** for common solutions
2. **Review the README.md** for project-specific instructions
3. **Check GitHub Issues** for known problems
4. **Create a new issue** with:
   - Your operating system
   - Foundry version (`forge --version`)
   - Complete error message
   - Steps to reproduce

## Success Criteria

✅ **Project builds successfully**  
✅ **All tests pass**  
✅ **Documentation is accessible**  
✅ **Can run deployment scripts**  
✅ **Code formatting works**  
✅ **Can make and test changes**  

Once all items are checked, you're ready to contribute to the ParityTax-AMM project!

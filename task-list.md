# Task List: Migrate rpi-hw-info from Submodule to PyPI Package

## Overview
Replace git submodule dependency with PyPI package installation in isolated venv

## Tasks

### 1. Setup and Preparation
- [ ] Create venv-based installation system in Makefile
- [ ] Update all rpi-hw-info invocations to use venv binary
- [ ] Test venv installation and tool functionality

### 2. Remove Submodule Infrastructure  
- [ ] Remove rpi-hw-info submodule from .gitmodules
- [ ] Remove rpi-hw-info directory
- [ ] Update .gitignore to exclude venv directory

### 3. Documentation Updates
- [ ] Update README.md to reflect PyPI installation approach
- [ ] Remove submodule references from documentation

### 4. Validation
- [ ] Test full build process with new approach
- [ ] Verify hardware detection still works correctly
- [ ] Ensure clean repository state

## Dependencies
- Python 3.8+ (standard on RaspberryPi OS)
- rpi-hw-info==2.0.4 from PyPI

## Benefits
- No git submodule complexity
- Version pinning for reproducible builds  
- Faster setup (no git operations)
- Cleaner repository structure 
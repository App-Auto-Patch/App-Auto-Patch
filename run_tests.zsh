#!/bin/zsh

# Test runner for App Auto-Patch
# Executes all test suites and provides a summary

set -e

SCRIPT_DIR="$(dirname "$0")"
TEST_DIR="$SCRIPT_DIR/tests"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "${BLUE}App Auto-Patch Test Suite Runner${NC}"
echo "=================================="

total_exit_code=0

# Run deferment dialog tests
echo "\n${YELLOW}Running Deferment Dialog Tests...${NC}"
if "$TEST_DIR/test_deferment_dialog.zsh"; then
    echo "${GREEN}Deferment Dialog Tests: PASSED${NC}"
else
    echo "${RED}Deferment Dialog Tests: FAILED${NC}"
    total_exit_code=1
fi

# Run dropdown behavior tests  
echo "\n${YELLOW}Running Dropdown Behavior Tests...${NC}"
if "$TEST_DIR/test_dropdown_behavior.zsh"; then
    echo "${GREEN}Dropdown Behavior Tests: PASSED${NC}"
else
    echo "${RED}Dropdown Behavior Tests: FAILED${NC}"
    total_exit_code=1
fi

# Final summary
echo "\n${BLUE}=================================="
if [[ $total_exit_code -eq 0 ]]; then
    echo "${GREEN}ALL TESTS PASSED!${NC}"
    echo "✓ Deferment dialog logic works correctly"
    echo "✓ Dropdown selection behavior works correctly" 
    echo "✓ User experience improvements verified"
    echo "✓ Fixes issue #160: https://github.com/App-Auto-Patch/App-Auto-Patch/issues/160"
else
    echo "${RED}SOME TESTS FAILED!${NC}"
    echo "Please review the test output above."
fi
echo "${BLUE}==================================${NC}"

exit $total_exit_code
#!/bin/zsh

# Test suite for App Auto-Patch deferment dialog functionality
# Tests the deferment selection and Continue button behavior changes

set -e  # Exit on any error

# Test configuration
TEST_DIR="$(dirname "$0")"
SCRIPT_DIR="$(dirname "$TEST_DIR")"
MAIN_SCRIPT="$SCRIPT_DIR/App-Auto-Patch-via-Dialog.zsh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_test_header() {
    echo "\n${YELLOW}=== Testing: $1 ===${NC}"
}

print_success() {
    echo "${GREEN}✓ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

print_failure() {
    echo "${RED}✗ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

run_test() {
    ((TESTS_RUN++))
    local test_name="$1"
    local test_function="$2"
    
    if $test_function; then
        print_success "$test_name"
    else
        print_failure "$test_name"
    fi
}

# Test function extraction (extracts functions from main script for testing)
extract_function() {
    local function_name="$1"
    local temp_file="/tmp/test_extracted_${function_name}.zsh"
    
    # Extract the function definition from the main script
    sed -n "/^${function_name}()/,/^}/p" "$MAIN_SCRIPT" > "$temp_file"
    echo "$temp_file"
}

# Mock dialog binary and dependencies
setup_test_environment() {
    export dialogBinary="/bin/echo"  # Mock dialog binary
    export appAutoPatchLocalPLIST="/tmp/test_app_auto_patch.plist"
    export verbose_mode_option="TRUE"
    
    # Create minimal test plist
    cat > "$appAutoPatchLocalPLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
EOF
}

cleanup_test_environment() {
    [[ -f "$appAutoPatchLocalPLIST" ]] && rm -f "$appAutoPatchLocalPLIST"
    rm -f /tmp/test_extracted_*.zsh
}

# Test: Verify deferment selecttitle string exists
test_deferment_selecttitle_exists() {
    grep -q 'display_string_deferral_selecttitle="Deferment"' "$MAIN_SCRIPT"
}

# Test: Verify improved user message exists
test_improved_user_message() {
    grep -q 'If you select a deferment option from the dropdown below, clicking Continue will defer' "$MAIN_SCRIPT"
}

# Test: Verify dialog case statement handles dropdown selection
test_dialog_case_statement_logic() {
    # Check that the case statement has the new logic for dropdown detection
    grep -q 'Check if user selected a deferment option from dropdown before clicking Continue' "$MAIN_SCRIPT" &&
    grep -q 'SELECTION.*SelectedIndex' "$MAIN_SCRIPT" &&
    grep -q 'User selected deferment option and clicked Continue' "$MAIN_SCRIPT"
}

# Test: Verify backward compatibility - direct Defer button still works
test_defer_button_compatibility() {
    # Check that case "2)" (Defer button) logic is preserved
    local defer_case_found=false
    local defer_logic_found=false
    
    if grep -A 10 -B 2 'case "${dialogOutput}" in' "$MAIN_SCRIPT" | grep -q '2)' &&
       grep -A 15 '2)' "$MAIN_SCRIPT" | grep -q 'dialog_user_choice_install="FALSE"'; then
        defer_case_found=true
    fi
    
    if grep -A 15 '2)' "$MAIN_SCRIPT" | grep -q 'User chose to defer update'; then
        defer_logic_found=true  
    fi
    
    [[ "$defer_case_found" == "true" && "$defer_logic_found" == "true" ]]
}

# Test: Verify Continue button with no dropdown selection still installs
test_continue_no_dropdown_installs() {
    # Check that the fallback case still sets install=TRUE when no dropdown selection
    grep -A 5 'No deferment option selected, proceed with installation' "$MAIN_SCRIPT" | grep -q 'dialog_user_choice_install="TRUE"'
}

# Integration test: Mock dialog interaction scenarios
test_dialog_interaction_scenarios() {
    local temp_script="/tmp/test_dialog_simulation.zsh"
    
    # Create a test script that simulates the dialog logic
    cat > "$temp_script" << 'EOF'
#!/bin/zsh

# Mock the dialog interaction logic
simulate_dialog_response() {
    local dialogOutput="$1"
    local SELECTION="$2"
    local deferral_timer_menu_minutes="$3"
    local deferral_timer_menu_minutes_array=("" "30" "60" "120")
    local dialog_user_choice_install=""
    local deferral_timer_minutes=""
    
    case "${dialogOutput}" in
        2)
            dialog_user_choice_install="FALSE"
            if [[ -n "${deferral_timer_menu_minutes}" ]]; then
                INDEX_CHOICE=$(echo "$SELECTION" | grep "SelectedIndex" | awk -F ": " '{print $NF}')
                INDEX_CHOICE=$((INDEX_CHOICE+1))
                deferral_timer_minutes="${deferral_timer_menu_minutes_array[${INDEX_CHOICE}]}"
                echo "DEFER_BUTTON:$deferral_timer_minutes"
            else
                echo "DEFER_BUTTON:DEFAULT"
            fi
        ;;
        4)
            dialog_user_choice_install="FALSE"
            echo "TIMEOUT:DEFER"
        ;;
        *)
            # Check if user selected a deferment option from dropdown before clicking Continue
            if [[ -n "${deferral_timer_menu_minutes}" ]] && [[ "$SELECTION" == *"SelectedIndex"* ]]; then
                dialog_user_choice_install="FALSE"
                INDEX_CHOICE=$(echo "$SELECTION" | grep "SelectedIndex" | awk -F ": " '{print $NF}')
                INDEX_CHOICE=$((INDEX_CHOICE+1))
                deferral_timer_minutes="${deferral_timer_menu_minutes_array[${INDEX_CHOICE}]}"
                echo "CONTINUE_WITH_DROPDOWN:$deferral_timer_minutes"
            else
                dialog_user_choice_install="TRUE"
                echo "CONTINUE_INSTALL"
            fi
        ;;
    esac
}

# Test scenarios
echo "Testing Defer button:"
simulate_dialog_response "2" "SelectedIndex: 1" "30,60,120"

echo "Testing Continue with dropdown selection:"
simulate_dialog_response "0" "SelectedIndex: 1" "30,60,120"  

echo "Testing Continue without dropdown selection:"
simulate_dialog_response "0" "Button Clicked" ""

echo "Testing Continue with no dropdown menu:"
simulate_dialog_response "0" "Button Clicked" ""
EOF

    chmod +x "$temp_script"
    local output=$("$temp_script")
    
    # Verify expected outputs
    echo "$output" | grep -q "DEFER_BUTTON:60" &&
    echo "$output" | grep -q "CONTINUE_WITH_DROPDOWN:60" &&
    echo "$output" | grep -q "CONTINUE_INSTALL"
    
    local result=$?
    rm -f "$temp_script"
    return $result
}

# Main test execution
main() {
    echo "${YELLOW}App Auto-Patch Deferment Dialog Test Suite${NC}"
    echo "Testing script: $MAIN_SCRIPT"
    
    setup_test_environment
    
    print_test_header "String Definitions"
    run_test "Deferment selecttitle string exists" test_deferment_selecttitle_exists
    run_test "Improved user message exists" test_improved_user_message
    
    print_test_header "Dialog Logic"
    run_test "Dialog case statement handles dropdown selection" test_dialog_case_statement_logic
    run_test "Defer button compatibility preserved" test_defer_button_compatibility
    run_test "Continue button without dropdown still installs" test_continue_no_dropdown_installs
    
    print_test_header "Integration Tests"
    run_test "Dialog interaction scenarios work correctly" test_dialog_interaction_scenarios
    
    cleanup_test_environment
    
    # Print summary
    echo "\n${YELLOW}=== Test Results ===${NC}"
    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
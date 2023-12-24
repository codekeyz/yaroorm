#!/bin/bash
# shellcheck disable=SC2156


TEST_DIRECTORY="test/integration"



# Function to find and run tests
run_tests() {
  local pattern="e2e_*.dart"

  # Find and run tests for each file
  find "$TEST_DIRECTORY" -type f -name "$pattern" -exec bash -c \
      'filename=$(basename {}); test_name="${filename%%.*}"; echo "Running tests for: $test_name"; dart test {} --coverage=coverage; echo' \;
}


run_tests;
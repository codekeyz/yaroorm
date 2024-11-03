#!/bin/bash
# shellcheck disable=SC2156

set -e

cd packages/yaroorm_test

TEST_DIRECTORY="test/integration"

pattern="*.e2e.dart"

for file in "$TEST_DIRECTORY"/$pattern; do
    filename=$(basename "$file")
    test_name="${filename%%.*}"
    echo "Running tests for: $test_name 📦"
    dart test "$file" --coverage=coverage --fail-fast
done

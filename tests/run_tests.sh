#!/bin/bash

# Main test runner for dotfiles repository
# Run with ./tests/run_tests.sh

# Set colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}=== Running Dotfiles Test Suite ===${NC}"

# Track overall success/failure
FAILED_TESTS=0

# Run unit tests
echo -e "\n${YELLOW}Running unit tests...${NC}"
for test_file in "$SCRIPT_DIR"/unit/*.sh; do
  if [ -f "$test_file" ]; then
    echo -e "Running $(basename "$test_file")..."
    if bash "$test_file"; then
      echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
    else
      echo -e "${RED}✗ $(basename "$test_file") failed${NC}"
      FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
  fi
done

# Run security tests
echo -e "\n${YELLOW}Running security tests...${NC}"
for test_file in "$SCRIPT_DIR"/security/*.sh; do
  if [ -f "$test_file" ]; then
    echo -e "Running $(basename "$test_file")..."
    if bash "$test_file"; then
      echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
    else
      echo -e "${RED}✗ $(basename "$test_file") failed${NC}"
      FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
  fi
done

# Run integration tests
echo -e "\n${YELLOW}Running integration tests...${NC}"
for test_file in "$SCRIPT_DIR"/integration/*.sh; do
  if [ -f "$test_file" ]; then
    echo -e "Running $(basename "$test_file")..."
    if bash "$test_file"; then
      echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
    else
      echo -e "${RED}✗ $(basename "$test_file") failed${NC}"
      FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
  fi
done

# Summary
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}$FAILED_TESTS test(s) failed!${NC}"
  exit 1
fi
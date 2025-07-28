#!/bin/bash

# Quick script to run bats tests
# Pass any arguments to bats (e.g., --timing, --verbose-run)
./bats/bin/bats "$@" test_squashMergePR.bats

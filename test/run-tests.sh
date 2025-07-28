#!/bin/bash

# Quick script to run bats tests
# Load bats-support and bats-assert
./bats/bin/bats "$@" test_squashMergePR.bats

#!/bin/bash

# Quick script to run bats tests
# Load bats-support and bats-assert
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
./bats/bin/bats "$@" test_squashMergePR.bats

#!/bin/bash

# Quick script to run bats tests
./bats/bin/bats "$@" test_squashMergePR.bats

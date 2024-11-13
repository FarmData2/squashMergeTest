# Squash Merge PR Script Documentation

## Overview

This documentation covers two Bash scripts:

1. `squashMergePR.bash`: The main script for squash merging pull requests with conventional commit messages.
2. `test_squashMergePR.bash`: A testing script to create test cases for the main script.

## Main Script: squashMergePR.bash

### Purpose

The `squashMergePR.bash` script automates the process of squash merging pull requests (PRs) while ensuring the commit message follows the conventional commit format. It handles various scenarios, including breaking changes and co-authors.

### Features

- Fetches PR details using GitHub CLI
- Parses PR title to extract type, scope, and description
- Handles breaking changes and co-authors
- Allows manual editing of the commit message before merging
- Performs squash merge using GitHub CLI

### Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- `jq` command-line JSON processor installed

### Usage

```bash
./squashMergePR.bash [options] [--pr <PR number>]
```

### Options

- `--type <type>`: Type of commit (e.g., feat, fix)
- `--scope <scope>`: Scope of the commit (e.g., lib, none)
- `--description <description>`: Description of the commit
- `--body <body>`: Body of the commit message
- `--breaking-change <yes|no>`: Specify if the commit introduces a breaking change
- `--breaking-change-description <desc>`: Description of the breaking change
- `--repo <GitHub repo URL>`: GitHub repository URL
- `--pr <PR number>`: The number of the pull request to merge
- `--coauthor <co-authors>`: Specify co-authors for the commit
- `--help`: Display help message and exit

### Workflow

1. The script checks for dependencies (`gh` and `jq`)
2. It authenticates with GitHub CLI if not already done
3. It fetches PR details based on the provided PR number
4. The PR title is parsed to extract type, scope, and description
5. Breaking changes and co-authors are extracted from commit messages
6. The user is prompted to review and optionally edit the commit message
7. The script performs a squash merge using the GitHub CLI

# Pull Request Test Script Documentation

## Overview

This document details a comprehensive test script for validating pull request (PR) handling with conventional commits, breaking changes, and co-authors. The script creates various test cases to ensure proper handling of different PR scenarios.

## Prerequisites

- Git installed and configured
- GitHub CLI (`gh`) installed and authenticated
- Bash shell environment
- Repository access with PR creation permissions

## Script Configuration

### Valid Types and Scopes

```bash
VALID_TYPES=("build" "chore" "ci" "docs" "feat" "fix" "perf" "refactor" "style" "test")
VALID_SCOPES=("dev" "comp" "lib" "fd2" "examples" "school" "none")
```

### Co-Authors Configuration
The script includes a predefined list of co-authors for testing collaboration scenarios:
```bash
COAUTHORS=(
    "Grant Braught <braught@dickinson.edu>"
    "John MacCormick <jmac@dickinson.edu>"
    "William Goble <goblew@dickinson.edu>"
    "Matt Ferland <ferlandm@dickinson.edu>"
    "Boosung Kim <kimbo@dickinson.edu>"
    "Ty Chermsirivatana <chermsit@dickinson.edu>"
)
```

## Test Cases

The script includes 15 distinct test cases, each designed to test specific aspects of PR handling:

### 1. Breaking Change in PR Description (Case 1)
- **Purpose**: Tests handling of breaking changes mentioned only in PR description
- **Behavior**: Creates a PR with breaking change notation in description only
- **Expected**: System should detect and handle breaking change from PR description

### 2. Breaking Change in Commit Message (Case 2)
- **Purpose**: Tests breaking changes in commit messages only
- **Behavior**: Creates commits with breaking change notations
- **Expected**: System should extract breaking changes from commit messages

### 3. Breaking Changes in Both Locations (Case 3)
- **Purpose**: Tests handling of breaking changes in both PR and commits
- **Behavior**: Includes breaking changes in both PR description and commits
- **Expected**: System should properly consolidate breaking changes from both sources

### 4. Co-author in PR Description (Case 4)
- **Purpose**: Tests co-author handling in PR description
- **Behavior**: Adds co-author information only in PR description
- **Expected**: System should correctly attribute co-authorship from PR

### 5. Co-author in Commit Message (Case 5)
- **Purpose**: Tests co-author handling in commits
- **Behavior**: Includes co-author information in commit messages
- **Expected**: System should extract co-author information from commits

### 6. Co-authors in Both Locations (Case 6)
- **Purpose**: Tests co-author handling from multiple sources
- **Behavior**: Includes co-authors in both PR description and commits
- **Expected**: System should properly combine co-author information

### 7. Invalid Type and Scope (Case 7)
- **Purpose**: Tests handling of invalid conventional commit format
- **Behavior**: Creates PR with invalid type and scope
- **Expected**: System should detect and handle invalid format appropriately

### 8. Missing Type and Scope (Case 8)
- **Purpose**: Tests handling of incomplete conventional commit format
- **Behavior**: Creates PR without type and scope
- **Expected**: System should handle missing components gracefully

### 9. Invalid Type Only (Case 9)
- **Purpose**: Tests handling of invalid commit type
- **Behavior**: Creates PR with invalid type but valid scope
- **Expected**: System should detect invalid type and respond appropriately

### 10. Invalid Scope Only (Case 10)
- **Purpose**: Tests handling of invalid scope
- **Behavior**: Creates PR with valid type but invalid scope
- **Expected**: System should detect invalid scope and respond appropriately

### 11. Missing Type Only (Case 11)
- **Purpose**: Tests handling of missing type
- **Behavior**: Creates PR without type but with scope
- **Expected**: System should detect missing type and handle accordingly

### 12. Missing Scope Only (Case 12)
- **Purpose**: Tests handling of missing scope
- **Behavior**: Creates PR with type but without scope
- **Expected**: System should handle missing scope appropriately

### 13. Empty Title Test (Case 13)
- **Purpose**: Tests handling of empty PR titles
- **Behavior**: Creates PR with empty title
- **Expected**: System should handle empty titles gracefully

### 14. Long Title Test (Case 14)
- **Purpose**: Tests handling of very long PR titles
- **Behavior**: Creates PR with exceptionally long title
- **Expected**: System should handle long titles appropriately

### 15. Special Characters Test (Case 15)
- **Purpose**: Tests handling of special characters
- **Behavior**: Creates PR with special characters in title
- **Expected**: System should properly handle special characters

## Script Usage

### Basic Usage
```bash
./test_squashMergePR.bash [OPTIONS]
```

### Available Options
- `-h, --help`: Display help information
- `-r, --reset`: Reset all test cases (removes branches and directories)
- `-a, --all`: Run all test cases
- `-s, --select CASES`: Run specific test cases (comma-separated list)
- `-R, --random`: Use random co-authors
- `-T, --types`: Use random types/scopes
- `--full-random`: Use both random co-authors and types/scopes

### Examples
```bash
# Run all test cases
./test_squashMergePR.bash -a

# Run specific test cases
./test_squashMergePR.bash -s 1,2,3

# Run with random co-authors
./test_squashMergePR.bash -a -R

# Reset all test cases
./test_squashMergePR.bash -r
```

## Important Functions

### generate_title()
Generates PR titles based on test parameters:
- Handles valid/invalid types and scopes
- Supports missing components
- Follows conventional commit format

### create_pr()
Creates test PRs with specified parameters:
- Generates branches
- Creates test files
- Makes commits with appropriate messages
- Handles breaking changes and co-authors
- Creates GitHub PR

### run_selected_tests()
Manages test case execution:
- Processes test case selection
- Handles random features
- Executes appropriate test cases

### reset_all_test_cases()
Cleans up test environment:
- Removes test branches
- Deletes test directories
- Resets to main branch

## Best Practices

1. **Test Environment**
   - Use a dedicated test repository
   - Ensure clean state before running tests
   - Regular cleanup using reset function

2. **Test Execution**
   - Run all tests before making changes
   - Test specific cases after modifications
   - Verify results manually

3. **Maintenance**
   - Keep co-author list updated
   - Maintain valid types and scopes
   - Regular script updates

## Troubleshooting

1. **Authentication Issues**
   - Verify GitHub CLI authentication
   - Check repository permissions
   - Ensure SSH keys are configured

2. **Failed PRs**
   - Check branch conflicts
   - Verify GitHub API access
   - Review error messages

3. **Clean Up**
   - Use reset option regularly
   - Manual cleanup if needed
   - Check remote branches

## References

- Conventional Commits: https://www.conventionalcommits.org/
- GitHub CLI documentation: https://cli.github.com/manual/
- Git documentation: https://git-scm.com/doc

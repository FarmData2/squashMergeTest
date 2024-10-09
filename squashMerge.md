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

## Testing Script: test_squashMergePR.bash

### Purpose

The `test_squashMergePR.bash` script creates various test cases to validate the functionality of the main `squashMergePR.bash` script.

### Features

- Creates PRs with different scenarios (invalid type, scope, breaking changes, etc.)
- Allows running all test cases or selecting specific ones
- Supports random co-author assignment
- Provides options to reset all test cases

### Usage

```bash
./test_squashMergePR.bash [OPTIONS]
```

### Options

- `-h, --help`: Display help message
- `-r, --reset`: Reset all test cases
- `-a, --all`: Run all test cases
- `-s, --select`: Select specific test cases to run
- `-R, --random`: Run test cases with random co-authors and possible duplicates

### Test Cases

1. New documentation with breaking change
2. Invalid type
3. Invalid scope
4. Missing type
5. Missing scope
6. Missing description in title
7. Breaking change
8. Multiple breaking changes
9. Very long description
10. Special characters

### Workflow

1. The script creates a new branch for each test case
2. It makes multiple commits with various scenarios (co-authors, breaking changes)
3. A PR is created for each test case
4. The user can then use the main script to test squash merging these PRs

## Best Practices

1. Always review the generated commit message before accepting the merge
2. Ensure your PR titles follow the conventional commit format for best results
3. Use the testing script to validate changes to the main script
4. Regularly update and authenticate your GitHub CLI to avoid issues

## Troubleshooting

- If you encounter authentication issues, run `gh auth login` manually
- Ensure you have the necessary permissions to merge PRs in the repository
- Check that your `gh` and `jq` installations are up to date


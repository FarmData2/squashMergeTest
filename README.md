# Squash Merge PR Script

## Overview

This repository contains a simple bash script allows a simplified workflow for handling pull request squash merges that adhere to conventional commit formatting.

### Scripts

1. **`squashMergePR.bash`** - Main script for squash merging PRs with conventional commit messages
2. **`testSquashMerge.bash`** - Test case generator for creating various PR scenarios

## Main Script: squashMergePR.bash

### Purpose

Automates squash merging of pull requests while ensuring commit messages follow conventional commit format. Handles breaking changes, co-authors, and various edge cases.

### Features

- Fetches PR details using GitHub CLI
- Parses PR titles to extract type, scope, and description
- Handles breaking changes and co-authors from both PR descriptions and commit messages
- Interactive commit message editing before merge
- Validates conventional commit format components
- Supports both HTTPS and SSH GitHub repository URLs

### Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- `jq` command-line JSON processor
- Git repository with GitHub remote

### Usage

```bash
./squashMergePR.bash [options] [--pr <PR number>]
```

### Options

- `--type <type>`: Commit type (feat, fix, docs, etc.)
- `--scope <scope>`: Commit scope (comp, lib, dev, etc.)
- `--description <description>`: Commit description
- `--body <body>`: Commit message body
- `--breaking-change <yes|no>`: Breaking change flag
- `--breaking-change-description <desc>`: Breaking change description
- `--repo <GitHub repo URL>`: Repository URL
- `--pr <PR number>`: Pull request number
- `--coauthor <co-authors>`: Co-authors for the commit
- `--help`: Display help message

### Valid Types

`build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `style`, `test`

### Valid Scopes

`dev`, `comp`, `lib`, `fd2`, `examples`, `school`, `none`

## Test Script: testSquashMerge.bash

### Purpose

Creates test PRs with various scenarios to validate the main script functionality.

### Test Cases

1. **Breaking change in PR description only**
2. **Breaking change in commit messages only**
3. **Breaking changes in both locations**
4. **Co-authors in PR description only**
5. **Co-authors in commit messages only**
6. **Co-authors in both locations**
7. **Invalid type and scope**
8. **Missing type and scope**
9. **Invalid type only**
10. **Invalid scope only**
11. **Missing type only**
12. **Missing scope only**
13. **Empty title**
14. **Very long title**
15. **Special characters in title**

### Usage

```bash
./testSquashMerge.bash [OPTIONS]
```

### Options

- `-h, --help`: Display help
- `-r, --reset`: Reset all test cases
- `-a, --all`: Run all test cases
- `-s, --select CASES`: Run specific test cases (comma-separated)
- `-R, --random`: Use random co-authors
- `-T, --types`: Use random types/scopes
- `--full-random`: Use both random co-authors and types/scopes

## Testing

### BATS Testing Framework

The project uses BATS (Bash Automated Testing System) for comprehensive testing.

### Test Structure

```
test/
├── bats/                    # BATS core (submodule)
├── test_helper/
│   ├── bats-support/        # BATS support library (submodule)
│   └── bats-assert/         # BATS assert library (submodule)
├── test_helper.bash         # Test helper functions
├── test_squashMergePR.bats  # Main script tests
└── run_tests.sh            # Test runner script
```

### Running Tests

```bash
# Run tests (For some reason, it needs to run in the test directory. I'm likely missing out on some trivial relative import I can make static but until then!)
cd test && ./run_tests.sh
```

## Setup

### Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd <repository-name>

# Initialize submodules
git submodule update --init --recursive

# Make scripts executable
chmod +x squashMergePR.bash testSquashMerge.bash test/run_tests.sh
```

### GitHub CLI Setup

```bash
# Install GitHub CLI
# Follow instructions at: https://cli.github.com/

# Authenticate
gh auth login
```

## Workflow

### Basic Usage

1. Navigate to your Git repository
2. Run the script with a PR number:
   ```bash
   ./squashMergePR.bash --pr 123
   ```
3. Review the generated commit message
4. Choose to accept, edit, or cancel
5. Script performs the squash merge

### Testing New Features

1. Create test cases using the test script:
   ```bash
   ./testSquashMerge.bash -s 1,2,3
   ```
2. Test the main script against generated PRs
3. Run the test suite to ensure functionality:
   ```bash
   cd test/ && ./run_tests.sh
   ```

## Error Handling

The scripts handle various error conditions:

- Missing dependencies (gh, jq)
- Invalid PR numbers or states
- Malformed repository URLs
- Invalid conventional commit formats
- Network connectivity issues

## Contributing

### Adding Tests

1. Add test cases to appropriate `.bats` files
2. Follow existing test patterns
3. Run test suite to verify changes
4. Update documentation as needed

### Modifying Scripts

1. Update relevant functions
2. Add corresponding tests
3. Run full test suite
4. Update README if interface changes

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [BATS Testing Framework](https://github.com/bats-core/bats-core)
- [Git Documentation](https://git-scm.com/doc)

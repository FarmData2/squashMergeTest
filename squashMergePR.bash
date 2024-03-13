#!/bin/bash

# Define valid types and scopes
VALID_TYPES=("build" "chore" "ci" "docs" "feat" "fix" "perf" "refactor" "style" "test")
VALID_SCOPES=("dev" "comp" "lib" "fd2" "examples" "school" "none") # Added 'none' for no scope

# Default values for flags
TYPE=""
SCOPE=""
PR_NUMBER=""
DESCRIPTION=""
PR_BODY=""
BREAKING_CHANGE=""
BREAKING_CHANGE_DESCRIPTION=""
REPO_URL=""

# Help function
displayHelp() {
    echo "Usage: $0 [options] [--pr-number <PR number>]"
    echo ""
    echo "Options:"
    echo "  --type <type>                           Type of commit (e.g., feat, fix)."
    echo "  --scope <scope>                         Scope of the commit (e.g., lib, none)."
    echo "  --description <description>             Description of the commit."
    echo "  --body <body>                           Body of the commit message."
    echo "  --breaking-change <yes|no>              Specify if the commit introduces a breaking change."
    echo "  --breaking-change-description <desc>    Description of the breaking change."
    echo "  --repo <GitHub repo URL>                GitHub repository URL. Supports HTTPS, SSH, and '.git' links (e.g., https://github.com/FarmData2/FarmData2, git@github.com:FarmData2/FarmData2.git)."
    echo "  --pr-number <PR number>                 The number of the pull request to merge."
    echo "  --help                                  Display this help message and exit."
    echo ""
    echo "If required options are not provided via command-line arguments,"
    echo "interactive prompts will be used to gather necessary information."
    echo ""
    echo "Example:"
    echo "  $0 --type feat --scope lib --description \"Add new feature\" --pr-number 123 --repo https://github.com/user/repo"
    echo ""
    echo "This script uses the GitHub CLI (gh) and expects it to be installed and authenticated."
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --type) TYPE="$2"; shift 2 ;;
        --scope) SCOPE="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --body) PR_BODY="$2"; shift 2 ;;
        --breaking-change) BREAKING_CHANGE="$2"; shift 2 ;;
        --breaking-change-description) BREAKING_CHANGE_DESCRIPTION="$2"; shift 2 ;;
        --repo) REPO_URL="$2"; shift 2 ;;
        --pr-number) PR_NUMBER="$2"; shift 2 ;;
        --help) displayHelp; exit 0 ;;
        *) echo "Unknown option: $1"; displayHelp; exit 1 ;;
    esac
done


# Helper function to check if an element is in an array
elementInArray() {
    local element
    shopt -s nocasematch
    for element in "${@:2}"; do
        [[ "$element" == "$1" ]] && { shopt -u nocasematch; return 0; }
    done
    shopt -u nocasematch
    return 1
}

# Helper function to print an array
printArray() {
    local arr=("$@")
    for item in "${arr[@]}"; do
        echo " - $item"
    done
}

# Helper function to prompt for a value with a default, displaying valid options and requiring valid input
promptForValue() {
    local prompt="$1"
    local defaultValue="$2"
    local validOptions=("${!3}")
    local -n resultVar=$4
    local value

    echo "$prompt"
    if [[ "${#validOptions[@]}" -ne 0 ]]; then
        echo "Valid options are:"
        for item in "${validOptions[@]}"; do
            echo " - $item"
        done
    fi
    read -p "Your choice [$defaultValue]: " value
    value="${value:-$defaultValue}"

    if [[ " ${validOptions[*]} " =~ " ${value} " || "$value" == "$defaultValue" ]]; then
        resultVar=$value
    else
        echo "Invalid input: '$value'. Please enter a valid value."
    fi
}
# Function to convert PR title to conventional commit format
convertToConventionalCommit() {
    local type=$1
    local scope=$2
    local description=$3
    local body=$4
    local breaking_change=$5
    local breaking_change_description=$6
    local commit_message="${type}"

    if [[ "$scope" != "none" ]]; then
        commit_message="${commit_message}(${scope})"
    fi

    commit_message="${commit_message}: ${description}"

    if [[ "$breaking_change" == "yes" && -n "$breaking_change_description" ]]; then
        commit_message="${commit_message}  BREAKING CHANGE: ${breaking_change_description}"
    elif [[ "$breaking_change" == "yes" ]]; then
        commit_message="${commit_message} ${body}"
    else
        commit_message="${commit_message} ${body}"
    fi

    echo "$commit_message"
}

# Function to check and handle GitHub CLI authentication
checkGhCliAuth() {
    echo "Checking GitHub CLI Authentication status..."
    if ! gh auth status > /dev/null 2>&1; then
        echo "You are not logged in to the GitHub CLI. Logging in..."
        gh auth login || { echo "GitHub CLI login failed. Please try again manually."; exit 1; }
    else
        echo "Logged in to the GitHub CLI."
    fi
}
# Function to perform a squash merge
squashMergePR() {
    local pr_number=$1
    local commit_message=$2
    local repo=$3
    local breaking_change_description=$4

    echo "Attempting to merge PR #$pr_number into $repo..."
    gh pr merge "$pr_number" --repo "$repo" -s -t "$commit_message" -b "$DESCRIPTION $breaking_change_description"
    echo "Successfully merged PR #$pr_number into $repo." || \
    { echo "Failed to merge PR #$pr_number into $repo."; return 1; }
}
# Function to check for gh and jq. Could expand with suggested install (Perhaps using apt if a Debian system)
checkDependencies() {
    local missing_dependencies=()

    if ! command -v gh &> /dev/null; then
        missing_dependencies+=("GitHub CLI (gh)")
    fi

    if ! command -v jq &> /dev/null; then
        missing_dependencies+=("jq (Command-line JSON processor)")
    fi

    if [ ${#missing_dependencies[@]} -ne 0 ]; then
        echo "The following dependencies are missing:"
        for dep in "${missing_dependencies[@]}"; do
            echo " - $dep"
        done
        echo "Please install them to continue."
        exit 1
    fi
}

# Prepare and extract PR details
prepPrDetails() {
    # Prompt for PR number if not provided
    if [ -z "$PR_NUMBER" ]; then
        while true; do
            read -p "Enter the Pull Request (PR) number: " PR_NUMBER
            if [ -z "$PR_NUMBER" ]; then
                echo "Error: PR number cannot be empty."
            elif ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
                echo "Error: PR number must be numeric."
            else
                break # Valid PR number entered
            fi
        done
    else
        echo "Working with detected PR number: $PR_NUMBER."
    fi

    # Fetch PR details
    if [ -n "$PR_NUMBER" ]; then
        echo "Fetching details for PR #$PR_NUMBER..."
        PR_DETAILS=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json title,body)
        PR_TITLE=$(echo "$PR_DETAILS" | jq -r '.title')
        PR_BODY=$(echo "$PR_DETAILS" | jq -r '.body')

        # Echo the current PR number and title
        echo "Current PR: #$PR_NUMBER - $PR_TITLE"
        echo "PR Decription: $PR_BODY"
    fi

    # Direct extraction of the DESCRIPTION from PR_TITLE, if not already provided
    if [ -z "$DESCRIPTION" ]; then
        DESCRIPTION=$(echo "$PR_TITLE" | sed -E 's/^[^:]+:?\s*\(?.*\)?\s*:\s*//')
    fi
}

# Run the dependency check (Pre entrypoint)
checkDependencies

# Main Entrypoint (Beginning with gh auth check)
checkGhCliAuth

# Prompt for number and display current title and body of PR. We assume that the body will be used as the commit description in the squash merge
prepPrDetails

# Interactive prompts for TYPE, SCOPE, DESCRIPTION if still needed
if [ -z "$TYPE" ]; then
    promptForValue "Enter commit type" "feat" VALID_TYPES[@] TYPE
fi

if [ -z "$SCOPE" ]; then
    promptForValue "Enter commit scope" "none" VALID_SCOPES[@] SCOPE
elif [[ "$SCOPE" == "none" ]]; then
    SCOPE="" # If scope is 'none', treat it as an empty string for formatting
fi

if [ -z "$DESCRIPTION" ]; then
    read -p "Enter commit description: " DESCRIPTION
    if [ -z "$DESCRIPTION" ]; then
        echo "Error: Commit description cannot be empty."
        exit 1
    fi
fi

# Extract repository info from URL or current git context
if [[ -n "$REPO_URL" ]]; then
    # Remove .git suffix if present
    REPO_URL="${REPO_URL%.git}"
    if [[ "$REPO_URL" =~ git@github.com:(.+)/(.+) ]]; then
        # SSH format URL
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    elif [[ "$REPO_URL" =~ https://github.com/(.+)/(.+) ]]; then
        # HTTPS format URL
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        echo "Error: Unable to parse GitHub repository URL."
        exit 1
    fi
elif git rev-parse --git-dir > /dev/null 2>&1; then
    # Attempt to extract from current git repository if in a git directory
    REPO_URL=$(git remote get-url origin)
    # Remove .git suffix if present
    REPO_URL="${REPO_URL%.git}"
    if [[ "$REPO_URL" =~ git@github.com:(.+)/(.+) ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    elif [[ "$REPO_URL" =~ https://github.com/(.+)/(.+) ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        echo "Error: Unable to parse origin URL of the current git repository."
        exit 1
    fi
else
    echo "Error: Repository URL is required if not in a git repository folder."
    exit 1
fi

# Handle BREAKING_CHANGE flag interactively if not set
if [ -z "$BREAKING_CHANGE" ]; then
    read -p "Is this a breaking change? (yes/no): " BREAKING_CHANGE
    if [[ "$BREAKING_CHANGE" != "yes" && "$BREAKING_CHANGE" != "no" ]]; then
        echo "Invalid input. Please enter 'yes' or 'no'."
        exit 1
    fi
fi

# Prompt for breaking change description if necessary
if [[ "$BREAKING_CHANGE" == "yes" && -z "$BREAKING_CHANGE_DESCRIPTION" ]]; then
    if [[ "$PR_BODY" =~ "BREAKING CHANGE:" ]]; then
        BREAKING_CHANGE_DESCRIPTION=$(echo "$PR_BODY" | sed -n '/BREAKING CHANGE:/,$p')
        echo "Breaking changes found and appended to commit."
    else
        echo "You indicated this is a breaking change. Please provide a specific description of the breaking change."
        read -p "Enter breaking change description: " BREAKING_CHANGE_DESCRIPTION
    fi
fi

# Add breaking change to PR body
if [[ "$BREAKING_CHANGE" == "yes" && -n "$BREAKING_CHANGE_DESCRIPTION" ]]; then
    PR_BODY="${PR_BODY}\n\nBREAKING CHANGE: ${BREAKING_CHANGE_DESCRIPTION}"
fi

# Generate the conventional commit message
CONV_COMMIT=$(convertToConventionalCommit "$TYPE" "$SCOPE" "$DESCRIPTION" "$PR_BODY" "$BREAKING_CHANGE" "$BREAKING_CHANGE_DESCRIPTION")

# Review, edit, or cancel the commit message
echo "Proposed commit message:"
echo "$CONV_COMMIT"
read -p "Do you want to (A)ccept, (E)dit, or (C)ancel? [A/e/c]: " choice

case $choice in
    [Ee]* )
        TMPFILE=$(mktemp)
        echo "$CONV_COMMIT" > "$TMPFILE"
        nano "$TMPFILE"
        CONV_COMMIT=$(cat "$TMPFILE")
        rm "$TMPFILE"
        ;;
    [Cc]* )
        echo "Operation cancelled."
        exit 0
        ;;
    * )
        echo "Accepting commit and beginning squash merge."
        ;;
esac

echo "Current PR number is "
echo "$PR_NUMBER"
# Perform the squash merge
squashMergePR "$PR_NUMBER" "$CONV_COMMIT" "$REPO"

#!/bin/bash

# Define valid types and scopes
VALID_TYPES=("build" "chore" "ci" "docs" "feat" "fix" "perf" "refactor" "style" "test")
VALID_SCOPES=("dev" "comp" "lib" "fd2" "examples" "school" "none")

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
    echo "  --repo <GitHub repo URL>                GitHub repository URL."
    echo "  --pr-number <PR number>                 The number of the pull request to merge."
    echo "  --help                                  Display this help message and exit."
    echo ""
    echo "If required options are not provided via command-line arguments,"
    echo "interactive prompts will be used to gather necessary information."
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
    local value valid

    echo "$prompt"
    if [[ "${#validOptions[@]}" -ne 0 ]]; then
        echo "Valid options are:"
        printArray "${validOptions[@]}"
    fi

    while true; do
        read -p "Your choice [$defaultValue]: " value
        value="${value:-$defaultValue}"
        valid=false

        for item in "${validOptions[@]}"; do
            if [[ "$value" == "$item" ]]; then
                valid=true
                break
            fi
        done

        if [ "$valid" = true ]; then
            resultVar=$value
            break
        else
            echo "Invalid input: '$value'. Please enter a valid value."
        fi
    done
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

    if [[ "$scope" != "none" && -n "$scope" ]]; then
        commit_message="${commit_message}(${scope})"
    fi

    commit_message="${commit_message}: ${description}"

    if [[ "$breaking_change" == "yes" && -n "$breaking_change_description" ]]; then
        commit_message="${commit_message}

BREAKING CHANGE: ${breaking_change_description}"
    elif [[ -n "$body" ]]; then
        commit_message="${commit_message}

${body}"
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

    echo "Attempting to merge PR #$pr_number into $repo..."
    gh pr merge "$pr_number" --repo "$repo" -s -t "$commit_message" -b "$DESCRIPTION $BREAKING_CHANGE_DESCRIPTION" || \
    { echo "Failed to merge PR #$pr_number into $repo."; return 1; }
    echo "Successfully merged PR #$pr_number into $repo."
}

# Function to check for gh and jq
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

# Function to parse PR title
parsePrTitle() {
    local pr_title="$1"
    local type=""
    local scope=""
    local description=""

    # Regex to fit conventional commit format.
    if [[ $pr_title =~ ^([a-z]+)(\(([a-z]+)\))?:\ (.+)$ ]]; then
        type="${BASH_REMATCH[1]}"
        scope="${BASH_REMATCH[3]}"
        description="${BASH_REMATCH[4]}"
    fi

    echo "$type|$scope|$description"
}

#  Function to parse PR Body
parsePrBody() {
    local pr_body="$1"
    local breaking_change=""
    local breaking_change_description=""

    if [[ "$pr_body" =~ BREAKING\ CHANGE:\ (.+) ]]; then
        breaking_change="yes"
        breaking_change_description="${BASH_REMATCH[1]}"
    elif [[ "$pr_body" =~ BREAKING\ CHANGES:\ (.+) ]]; then
        breaking_change="yes"
        breaking_change_description="${BASH_REMATCH[1]}"
    fi

    echo "$breaking_change|$breaking_change_description"
}

# Function to prepare PR body
prepPrDetails() {
    local valid_pr_found=false

    while [ "$valid_pr_found" == false ]; do
        # Prompt for PR number if not provided
        if [ -z "$PR_NUMBER" ]; then
            read -p "Enter the Pull Request (PR) number: " PR_NUMBER
        fi

        if [ -z "$PR_NUMBER" ]; then
            echo "Error: PR number cannot be empty."
            PR_NUMBER=""
        elif ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
            echo "Error: PR number must be numeric."
            PR_NUMBER=""
        else
            # Fetch PR details
            echo "Fetching details for PR #$PR_NUMBER..."
            PR_DETAILS=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json title,body,state,isDraft,author,changedFiles,mergeStateStatus)
            PR_TITLE=$(echo "$PR_DETAILS" | jq -r '.title')
            PR_BODY=$(echo "$PR_DETAILS" | jq -r '.body')
            PR_STATE=$(echo "$PR_DETAILS" | jq -r '.state')
            PR_IS_DRAFT=$(echo "$PR_DETAILS" | jq -r '.isDraft')
            PR_AUTHOR=$(echo "$PR_DETAILS" | jq -r '.author.login')
            PR_CHANGED_FILES=$(echo "$PR_DETAILS" | jq -r '.changedFiles')
            PR_MERGE_STATE_STATUS=$(echo "$PR_DETAILS" | jq -r '.mergeStateStatus')

            # Parse PR title and body
            IFS='|' read -r PARSED_TYPE PARSED_SCOPE PARSED_DESCRIPTION <<< "$(parsePrTitle "$PR_TITLE")"
            IFS='|' read -r PARSED_BREAKING_CHANGE PARSED_BREAKING_CHANGE_DESCRIPTION <<< "$(parsePrBody "$PR_BODY")"

            # Echo PR details
            echo ""
            echo "Current PR: #$PR_NUMBER - $PR_TITLE"
            echo "PR Description: $PR_BODY"
            echo "Author: $PR_AUTHOR"
            echo "Changed Files: $PR_CHANGED_FILES"
            echo "Merge State Status: $PR_MERGE_STATE_STATUS"
            echo ""

            # Check PR state and merge status
            if [[ "$PR_STATE" == "closed" ]]; then
                echo "This PR is closed."
                PR_NUMBER=""
            elif [[ "$PR_IS_DRAFT" == "true" ]]; then
                echo "This PR is in draft state and is not ready to be merged. Please enter a different PR number."
                PR_NUMBER=""
            elif [[ "$PR_MERGE_STATE_STATUS" != "CLEAN" ]]; then
                echo "This PR is not in a state that can be merged (Merge State Status: $PR_MERGE_STATE_STATUS). Please choose a different PR or resolve the issues."
                PR_NUMBER=""
            else
                echo "This PR is open and ready for further actions."
                echo ""
                valid_pr_found=true
            fi
        fi
    done

    # Use parsed values or prompt for missing/invalid parts
    if [ -z "$TYPE" ]; then
        if elementInArray "$PARSED_TYPE" "${VALID_TYPES[@]}"; then
            TYPE="$PARSED_TYPE"
            echo "Using type '$TYPE' from PR title."
        else
            promptForValue "Please enter a valid commit type" "feat" VALID_TYPES[@] TYPE
        fi
    fi

    if [ -z "$SCOPE" ]; then
        if elementInArray "$PARSED_SCOPE" "${VALID_SCOPES[@]}"; then
            SCOPE="$PARSED_SCOPE"
            echo "Using scope '$SCOPE' from PR title."
        else
            promptForValue "Enter commit scope" "none" VALID_SCOPES[@] SCOPE
        fi
    fi

    if [ -z "$DESCRIPTION" ]; then
        if [ -n "$PARSED_DESCRIPTION" ]; then
            DESCRIPTION="$PARSED_DESCRIPTION"
            echo "Using description '$DESCRIPTION' from PR title."
        else
            read -p "Enter commit description: " DESCRIPTION
            if [ -z "$DESCRIPTION" ]; then
                echo "Error: Commit description cannot be empty."
                exit 1
            fi
        fi
    fi

    # Handle breaking changes
    if [ -z "$BREAKING_CHANGE" ]; then
        if [ "$PARSED_BREAKING_CHANGE" == "yes" ]; then
            BREAKING_CHANGE="yes"
            echo "Breaking change detected in PR body."
        else
            read -p "Is this a breaking change? (yes/no): " BREAKING_CHANGE
        fi
    fi

    # Normalize BREAKING_CHANGE value
    case "$BREAKING_CHANGE" in
        yes|y) BREAKING_CHANGE="yes" ;;
        no|n|*) BREAKING_CHANGE="no" ;;
    esac

    if [ "$BREAKING_CHANGE" == "yes" ]; then
        if [ -z "$BREAKING_CHANGE_DESCRIPTION" ]; then
            if [ -n "$PARSED_BREAKING_CHANGE_DESCRIPTION" ]; then
                BREAKING_CHANGE_DESCRIPTION="$PARSED_BREAKING_CHANGE_DESCRIPTION"
                echo "Using breaking change description from PR body."
            else
                read -p "Enter breaking change description: " BREAKING_CHANGE_DESCRIPTION
            fi
        fi
    fi
}

# Main script execution
checkDependencies
checkGhCliAuth

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

# Begin prepPrDetails call
prepPrDetails

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
        ${EDITOR:-nano} "$TMPFILE"
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

# Perform the squash merge
squashMergePR "$PR_NUMBER" "$CONV_COMMIT" "$REPO"

# Check the result of squage merge
if [ $? -eq 0 ]; then
    echo "Pull Request #$PR_NUMBER has been successfully merged."
else
    echo "Failed to merge Pull Request #$PR_NUMBER. Please check the error message above and try again."
    exit 1
fi

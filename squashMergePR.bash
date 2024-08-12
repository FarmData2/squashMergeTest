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
    echo "Usage: $0 [options] [--pr <PR number>]"
    echo ""
    echo "Options:"
    echo "  --type <type>                           Type of commit (e.g., feat, fix)."
    echo "  --scope <scope>                         Scope of the commit (e.g., lib, none)."
    echo "  --description <description>             Description of the commit."
    echo "  --body <body>                           Body of the commit message."
    echo "  --breaking-change <yes|no>              Specify if the commit introduces a breaking change."
    echo "  --breaking-change-description <desc>    Description of the breaking change."
    echo "  --repo <GitHub repo URL>                GitHub repository URL."
    echo "  --pr <PR number>                        The number of the pull request to merge."
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
        --pr) PR_NUMBER="$2"; shift 2 ;;
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

        if [[ "${#validOptions[@]}" -eq 0 ]]; then
            valid=true
        else
            for item in "${validOptions[@]}"; do
                if [[ "$value" == "$item" ]]; then
                    valid=true
                    break
                fi
            done
        fi

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

    if [[ -n "$scope" && "$scope" != "none" ]]; then
        commit_message="${commit_message}(${scope})"
    fi

    commit_message="${commit_message}: ${description}"

    if [[ -n "$body" ]]; then
        commit_message="${commit_message}\n\n${body}"
    fi

    if [[ "$breaking_change" == "yes" && -n "$breaking_change_description" ]]; then
        commit_message="${commit_message}\n\nBREAKING CHANGE: ${breaking_change_description}"
    fi

    echo -e "$commit_message"
}

# Function to check and handle GitHub CLI authentication
checkGhCliAuth() {
    echo "Checking GitHub CLI Authentication status..."
    if ! gh auth status &> /dev/null; then
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
    if gh pr merge "$pr_number" --repo "$repo" -s -t "$commit_message"; then
        echo "Successfully merged PR #$pr_number into $repo."
    else
        echo "Failed to merge PR #$pr_number into $repo."
        return 1
    fi
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
parsePRTitle() {
    local pr_title=$1
    local -n type_ref=$2
    local -n scope_ref=$3
    local -n description_ref=$4

    if [[ $pr_title =~ ^([a-zA-Z]+)(\(([^)]+)\))?:\ (.+)$ ]]; then
        type_ref="${BASH_REMATCH[1]}"
        scope_ref="${BASH_REMATCH[3]}"
        description_ref="${BASH_REMATCH[4]}"
    else
        type_ref=""
        scope_ref=""
        description_ref="$pr_title"
    fi
}

# Function to retrieve PR details from Github
getPrDetails() {
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

            # Parse PR title
            parsePRTitle "$PR_TITLE" PR_TYPE PR_SCOPE PR_DESCRIPTION

            # Echo PR details
            echo ""
            echo "Current PR: #$PR_NUMBER - $PR_TITLE"
            echo "PR Description: $PR_BODY"
            echo "Author: $PR_AUTHOR"
            echo "Changed Files: $PR_CHANGED_FILES"
            echo "Merge State Status: $PR_MERGE_STATE_STATUS"
            echo ""

            # Check PR state
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
}

# Function to validate type and scope
validateTypeAndScope() {
    local -n type_ref=$1
    local -n scope_ref=$2

    if ! elementInArray "$type_ref" "${VALID_TYPES[@]}"; then
        echo "Invalid commit type: $type_ref"
        promptForValue "Please enter a valid commit type" "feat" VALID_TYPES[@] type_ref
    fi

    if [ -z "$scope_ref" ] || ! elementInArray "$scope_ref" "${VALID_SCOPES[@]}"; then
        promptForValue "Please enter a valid commit scope" "none" VALID_SCOPES[@] scope_ref
    fi
}

# Function to parse breaking change from PR body
parseBreakingChange() {
    local pr_body=$1
    local -n breaking_change_ref=$2
    local -n breaking_change_description_ref=$3

    if [[ "$pr_body" =~ BREAKING[[:space:]]CHANGE:[[:space:]]*(.*) ]]; then
        breaking_change_ref="yes"
        breaking_change_description_ref="${BASH_REMATCH[1]}"
    else
        breaking_change_ref="no"
        breaking_change_description_ref=""
    fi
}

# Main Entrypoint
checkDependencies
checkGhCliAuth

# Extract repository info from URL or current git context
if [[ -n "$REPO_URL" ]]; then
    REPO_URL="${REPO_URL%.git}"
    if [[ "$REPO_URL" =~ git@github.com:(.+)/(.+) ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    elif [[ "$REPO_URL" =~ https://github.com/(.+)/(.+) ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        echo "Error: Unable to parse GitHub repository URL."
        exit 1
    fi
elif git rev-parse --git-dir > /dev/null 2>&1; then
    REPO_URL=$(git remote get-url origin)
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

getPrDetails

# Validate and use PR details if not provided via command line
if [ -z "$TYPE" ]; then
    TYPE="$PR_TYPE"
fi
if [ -z "$SCOPE" ]; then
    SCOPE="$PR_SCOPE"
fi
if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="$PR_DESCRIPTION"
fi

# Validate type and scope
validateTypeAndScope TYPE SCOPE

if [ -z "$DESCRIPTION" ]; then
    read -p "Enter commit description: " DESCRIPTION
    while [ -z "$DESCRIPTION" ]; do
        echo "Error: Commit description cannot be empty."
        read -p "Enter commit description: " DESCRIPTION
    done
fi

# Handle BREAKING_CHANGE flag
if [ -z "$BREAKING_CHANGE" ]; then
    parseBreakingChange "$PR_BODY" BREAKING_CHANGE BREAKING_CHANGE_DESCRIPTION
fi

if [[ "$BREAKING_CHANGE" == "yes" && -z "$BREAKING_CHANGE_DESCRIPTION" ]]; then
    read -p "Enter breaking change description: " BREAKING_CHANGE_DESCRIPTION
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
        ${EDITOR:-nano} "$TMPFILE"
        CONV_COMMIT=$(cat "$TMPFILE")
        rm "$TMPFILE"
        ;;
    [Cc]* )
        echo "Operation cancelled."
        exit 1
        ;;
    * )
        echo "Accepting commit and beginning squash merge."
        ;;
esac

# Perform the squash merge
squashMergePR "$PR_NUMBER" "$CONV_COMMIT" "$REPO"

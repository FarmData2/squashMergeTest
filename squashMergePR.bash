#!/bin/bash

# Define ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define valid types and scopes
VALID_TYPES=("build" "chore" "ci" "docs" "feat" "fix" "perf" "refactor" "style" "test")
VALID_SCOPES=("dev" "comp" "lib" "fd2" "examples" "school" "none")

# Default values for flags
COAUTHORS=""
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
    echo "  --coauthor <co-authors>                 Specify co-authors for the commit. (e.g., Ty Chermsirivatana <chermsit@dickinson.edu>, Grant Braught <braught@dickinson.edu>)"
    echo "  --help                                  Display this help message and exit."
    echo ""
    echo "If required options are not provided via command-line arguments,"
    echo "interactive prompts will be used to gather necessary information."
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --coauthor) COAUTHORS="$2"; shift 2 ;;
        --type) TYPE="$2"; shift 2 ;;
        --scope) SCOPE="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --body) PR_BODY="$2"; shift 2 ;;
        --breaking-change) BREAKING_CHANGE="$2"; shift 2 ;;
        --breaking-change-description) BREAKING_CHANGE_DESCRIPTION="$2"; shift 2 ;;
        --repo) REPO_URL="$2"; shift 2 ;;
        --pr) PR_NUMBER="$2"; shift 2 ;;
        --help) displayHelp; exit 0 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; displayHelp; exit 1 ;;
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
            echo -e "${RED}Invalid input: '$value'. Please enter a valid value.${NC}"
        fi
    done
}

# Function to extract breaking changes and co-authors from PR. Turns out that you just need to look at breaking changes. 
extractCommitInfo() {
    local pr_number="$1"
    local breaking_changes=""
    local co_authors=()

    # Fetch all commit SHAs for the PR
    local commit_shas=$(gh pr view "$pr_number" --json commits --jq '.commits[].oid')

    # Iterate through each commit SHA
    while read -r sha; do
        # Fetch full commit message
        local commit_message=$(gh api "repos/:owner/:repo/commits/$sha" --jq '.commit.message')

        # Process each line of the commit message
        while IFS= read -r line; do
            if [[ "$line" =~ ^BREAKING[[:space:]]CHANGE:(.*)$ ]]; then
                # Append breaking change with proper newline separation
                breaking_changes+="BREAKING CHANGE:${BASH_REMATCH[1]}"$'\n'
            elif [[ "$line" =~ ^[[:space:]](.*)$ ]] && [[ -n "$breaking_changes" ]]; then
                # Append multiline description to the last breaking change
                breaking_changes+=" ${BASH_REMATCH[1]}"$'\n'
            elif [[ "$line" =~ ^Co-authored-by:(.*)$ ]]; then
                # Collect co-authors, removing commas from emails
                local co_author_entry=$(echo "${BASH_REMATCH[1]}" | sed 's/,//g')
                co_authors+=("$co_author_entry")
            fi
        done < <(echo "$commit_message")
    done <<< "$commit_shas"

    # Process co-authors
    declare -A unique_co_authors
    for author in "${co_authors[@]}"; do
        local author_email=$(echo "$author" | grep -oP '<\K[^>]+')
        if [[ -n "$author_email" ]]; then
            local username=$(echo "$author_email" | cut -d@ -f1)
            formatted_author="Co-authored-by: $username <$author_email>"
            unique_co_authors["$author_email"]="$formatted_author"
        fi
    done

    # Combine breaking changes and co-authors
    local formatted_output=""
    if [ -n "$breaking_changes" ]; then
        formatted_output+="$breaking_changes"
    fi

    if [ ${#unique_co_authors[@]} -gt 0 ]; then
        formatted_output+=$'\n'
        for author in "${unique_co_authors[@]}"; do
            formatted_output+="$author"$'\n'
        done
    fi

    # Remove trailing newlines
    formatted_output=$(echo "$formatted_output" | sed -e 's/[[:space:]]*$//')
    echo "$formatted_output"
}

# Function to convert to conventional commit.
convertToConventionalCommit() {
    local type="$1"
    local scope="$2"
    local title="$3"
    local body="$4"
    local breaking_changes="$5"
    local co_authors="$6"
    local commit_message=""

    # Construct the first line of the commit message
    commit_message="${type}"
    if [[ "$scope" != "none" && -n "$scope" ]]; then
        commit_message="${commit_message}(${scope})"
    fi
    # Ensure proper spacing after colon
    commit_message="${commit_message}: ${title}"

    # Rest of the function remains the same...
    # Add body if not empty
    if [[ -n "$body" ]]; then
        # Extract breaking changes and co-authors before cleaning
        local body_breaking_changes=$(echo "$body" | grep -E '^BREAKING CHANGE:.*' || true)
        local body_co_authors=$(echo "$body" | grep -E '^Co-authored-by:.*' || true)
        
        # Clean the body by removing breaking changes and co-authors lines
        local cleaned_body=$(echo "$body" | grep -v '^BREAKING CHANGE:' | grep -v '^Co-authored-by:' | sed '/^$/d')
        
        if [[ -n "$cleaned_body" ]]; then
            commit_message="${commit_message}

${cleaned_body}"
        fi
    fi

    # Add breaking changes if present (with proper spacing)
    if [[ -n "$breaking_changes" ]]; then
        commit_message="${commit_message}

${breaking_changes}"
    fi

    # Add co-authors if present (with proper spacing)
    if [[ -n "$co_authors" ]]; then
        commit_message="${commit_message}

${co_authors}"
    fi

    # Clean up excessive newlines while preserving required formatting
    commit_message=$(echo -e "$commit_message" | awk '
        NR==1 {print; next}
        /^$/ {
            if (!blank) {
                print
                blank=1
            }
            next
        }
        {
            blank=0
            print
        }
    ')

    echo "$commit_message"
}

# Function to check and handle GitHub CLI authentication
checkGhCliAuth() {
    echo -e "${BLUE}Checking GitHub CLI Authentication status...${NC}"
    if ! gh auth status > /dev/null 2>&1; then
        echo -e "${YELLOW}You are not logged in to the GitHub CLI. Logging in...${NC}"
        gh auth login || { echo -e "${RED}GitHub CLI login failed. Please try again manually.${NC}"; exit 1; }
    else
        echo -e "${GREEN}Logged in to the GitHub CLI.${NC}"
    fi
}

# Function to perform a squash merge
squashMergePR() {
    local pr_number=$1
    local commit_message=$2
    local repo=$3

    # Extract the first line as the title
    local title=$(echo "$commit_message" | head -n 1)
    # Extract the rest as the body
    local body=$(echo "$commit_message" | tail -n +2)

    echo -e "${BLUE}Attempting to merge PR #$pr_number into $repo...${NC}"
    if gh pr merge "$pr_number" --repo "$repo" -s -t "$title" -b "$body"; then
        echo -e "${GREEN}Successfully merged PR #$pr_number into $repo.${NC}"
        return 0
    else
        echo -e "${RED}Failed to merge PR #$pr_number into $repo.${NC}"
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
        echo -e "${RED}The following dependencies are missing:${NC}"
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
    
    # Simplified regex pattern for bash
    if [[ $pr_title =~ ^([[:alnum:]]+)\(([[:alnum:]0-9]+)\):[[:space:]]*(.*) ]]; then
        type="${BASH_REMATCH[1]}"
        scope="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"
    elif [[ $pr_title =~ ^([[:alnum:]]+):[[:space:]]*(.*) ]]; then
        type="${BASH_REMATCH[1]}"
        description="${BASH_REMATCH[2]}"
    fi
    
    echo "$type|$scope|$description"
}

parsePrBody() {
    local pr_body="$1"
    local breaking_changes="$2"
    local co_authors="$3"
    local body=""

    # Use the entire PR body as the commit description
    body="$pr_body"

    # Append breaking changes if they exist
    if [[ -n "$breaking_changes" ]]; then
        body+="\n\n"
        IFS=$'\n' read -rd '' -a bc_array <<< "$breaking_changes"
        for change in "${bc_array[@]}"; do
            body+="BREAKING CHANGE: $change\n"
        done
    fi

    # Append co-authors if they exist
    if [[ -n "$co_authors" ]]; then
        body+="\n"
        IFS=$'\n' read -rd '' -a ca_array <<< "$co_authors"
        for author in "${ca_array[@]}"; do
            body+="Co-authored-by: $author\n"
        done
    fi

    # Trim leading/trailing whitespace
    body=$(echo -e "$body" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    echo "$body"
}


# Function to check PR title components
checkPrTitleComponents() {
    local type="$1"
    local scope="$2"
    local description="$3"
    local result=""

    if [ -z "$type" ]; then
        result+="Missing: type. "
    elif ! elementInArray "$type" "${VALID_TYPES[@]}"; then
        result+="Invalid: type. "
    fi

    if [ -z "$scope" ]; then
        result+="Missing: scope. "
    elif [ "$scope" != "none" ] && ! elementInArray "$scope" "${VALID_SCOPES[@]}"; then
        result+="Invalid: scope. "
    fi

    if [ -z "$description" ]; then
        result+="Missing: description. "
    fi

    echo "$result"
}

prepPrDetails() {
    local valid_pr_found=false

    while [ "$valid_pr_found" == false ]; do
        # Prompt for PR number if not provided
        if [ -z "$PR_NUMBER" ]; then
            read -p "Enter the Pull Request (PR) number: " PR_NUMBER
        fi
        
        if [ -z "$PR_NUMBER" ]; then
            echo -e "${RED}Error: PR number cannot be empty.${NC}"
            PR_NUMBER=""
        elif ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Error: PR number must be numeric.${NC}"
            PR_NUMBER=""
        else
            # Fetch PR details
            echo -e "${BLUE}Fetching details for PR #$PR_NUMBER...${NC}"
            PR_DETAILS=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json title,body,state,isDraft,author,changedFiles,mergeStateStatus)
            PR_TITLE=$(echo "$PR_DETAILS" | jq -r '.title')
            PR_BODY=$(echo "$PR_DETAILS" | jq -r '.body')
            PR_STATE=$(echo "$PR_DETAILS" | jq -r '.state')
            PR_IS_DRAFT=$(echo "$PR_DETAILS" | jq -r '.isDraft')
            PR_AUTHOR=$(echo "$PR_DETAILS" | jq -r '.author.login')
            PR_CHANGED_FILES=$(echo "$PR_DETAILS" | jq -r '.changedFiles')
            PR_MERGE_STATE_STATUS=$(echo "$PR_DETAILS" | jq -r '.mergeStateStatus')

            # Parse PR title
            IFS='|' read -r PARSED_TYPE PARSED_SCOPE PARSED_DESCRIPTION <<< "$(parsePrTitle "$PR_TITLE")"

            # Extract commit info
            IFS='|' read -r BREAKING_CHANGES CO_AUTHORS <<< "$(extractCommitInfo "$PR_NUMBER")"

            # Check PR title components
            TITLE_CHECK_RESULT=$(checkPrTitleComponents "$PARSED_TYPE" "$PARSED_SCOPE" "$PARSED_DESCRIPTION")

            # Echo PR details
            echo ""
            echo -e "${GREEN}Current PR: #$PR_NUMBER - $PR_TITLE${NC}"
            echo -e "${YELLOW}PR Description: $PR_BODY${NC}"
            echo -e "Author: $PR_AUTHOR"
            echo -e "Changed Files: $PR_CHANGED_FILES"
            echo -e "Merge State Status: $PR_MERGE_STATE_STATUS"
            echo ""
            
            if [ -n "$TITLE_CHECK_RESULT" ]; then
                echo -e "${YELLOW}Issues with PR title:${NC}"
                if [[ $TITLE_CHECK_RESULT == *"Missing:"* ]]; then
                    echo -e "${RED}Missing components:${NC}"
                    if [[ $TITLE_CHECK_RESULT == *"Missing: type"* ]]; then
                        echo -e "  - Type (e.g., feat, fix, docs)"
                        promptForValue "Please enter a valid type" "feat" VALID_TYPES[@] PARSED_TYPE
                    fi
                    if [[ $TITLE_CHECK_RESULT == *"Missing: scope"* ]]; then
                        echo -e "  - Scope (e.g., dev, comp, lib)"
                        promptForValue "Please enter a valid scope" "none" VALID_SCOPES[@] PARSED_SCOPE
                    fi
                    if [[ $TITLE_CHECK_RESULT == *"Missing: description"* ]]; then
                        echo -e "  - Description"
                        read -p "Please enter a description: " PARSED_DESCRIPTION
                    fi
                fi
                if [[ $TITLE_CHECK_RESULT == *"Invalid:"* ]]; then
                    echo -e "${RED}Invalid components:${NC}"
                    if [[ $TITLE_CHECK_RESULT == *"Invalid: type"* ]]; then
                        echo -e "  - Type: '$PARSED_TYPE' is not a valid type"
                        echo -e "    Valid types are: ${VALID_TYPES[*]}"
                        promptForValue "Please enter a valid type" "$PARSED_TYPE" VALID_TYPES[@] PARSED_TYPE
                    fi
                    if [[ $TITLE_CHECK_RESULT == *"Invalid: scope"* ]]; then
                        echo -e "  - Scope: '$PARSED_SCOPE' is not a valid scope"
                        echo -e "    Valid scopes are: ${VALID_SCOPES[*]}"
                        promptForValue "Please enter a valid scope" "$PARSED_SCOPE" VALID_SCOPES[@] PARSED_SCOPE
                    fi
                fi
                echo -e "${YELLOW}Please consider updating your PR title to follow the conventional commit format:${NC}"
                echo -e "${BLUE}type(scope): description${NC}"
            fi

            # Check PR state and merge status
            if [[ "$PR_STATE" == "closed" ]]; then
                echo -e "${RED}This PR is closed.${NC}"
                PR_NUMBER=""
            elif [[ "$PR_IS_DRAFT" == "true" ]]; then
                echo -e "${YELLOW}This PR is in draft state and is not ready to be merged. Please enter a different PR number.${NC}"
                PR_NUMBER=""
            elif [[ "$PR_MERGE_STATE_STATUS" == "UNKNOWN" ]]; then
                echo -e "${YELLOW}Unable to determine merge state status. This may be due to GitHub API limitations. Proceeding with caution.${NC}"
                valid_pr_found=true
            elif [[ "$PR_MERGE_STATE_STATUS" != "CLEAN" ]]; then
                echo -e "${RED}This PR is not in a state that can be merged (Merge State Status: $PR_MERGE_STATE_STATUS). Please choose a different PR or resolve the issues.${NC}"
                PR_NUMBER=""
            else
                echo -e "${GREEN}This PR is open and ready for further actions.${NC}"
                echo ""
                valid_pr_found=true
            fi
        fi
    done

    # Extract commit info 
    COMMIT_INFO=$(extractCommitInfo "$PR_NUMBER")
    # Construct the new title with inline replacements
    NEW_TITLE="$PARSED_DESCRIPTION"

    # Parse PR body with additional info
    PARSED_BODY="$PR_BODY"
        if [ -n "$COMMIT_INFO" ]; then
            PARSED_BODY+=$'\n\n'"$COMMIT_INFO"
        fi
   
    # Generate the conventional commit message
    CONV_COMMIT=$(convertToConventionalCommit "$PARSED_TYPE" "$PARSED_SCOPE" "$NEW_TITLE" "$PARSED_BODY")

    # Review, edit, or cancel the commit message
    while true; do
        echo -e "${BLUE}Proposed commit message:${NC}"
        echo -e "${YELLOW}$CONV_COMMIT${NC}"
        read -p "Do you want to (A)ccept, (E)dit, or (C)ancel? [A/e/c]: " choice

        case $choice in
            [Aa]* )
                echo -e "${GREEN}Proceeding with squash merge...${NC}"
                break 
                ;;
            [Ee]* )
                TMPFILE=$(mktemp)
                echo "$CONV_COMMIT" > "$TMPFILE"
                ${EDITOR:-nano} "$TMPFILE"
                CONV_COMMIT=$(cat "$TMPFILE")
                rm "$TMPFILE"
                ;;
            [Cc]* )
                echo -e "${YELLOW}Operation cancelled.${NC}"
                exit 0
                ;;
            * )
                echo -e "${RED}Invalid choice. Please enter 'A' to accept, 'E' to edit, or 'C' to cancel.${NC}"
                ;;
        esac
    done
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
        echo -e "${RED}Error: Unable to parse GitHub repository URL.${NC}"
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
        echo -e "${RED}Error: Unable to parse origin URL of the current git repository.${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: Repository URL is required if not in a git repository folder.${NC}"
    exit 1
fi

# Function to list open PRs

list_prs() {
    local prs
    prs=$(gh pr list --json number,title,headRefName --jq '.[] | "\(.number)|\(.title)|\(.headRefName)"')
    
    if [ -z "$prs" ]; then
        echo "No open pull requests found."
        return
    fi

    echo "Open Pull Requests:"
    echo "$prs" | while IFS='|' read -r number title branch; do
        printf "PR #%s: %s (%s)\n" "$number" "$title" "$branch"
    done
}

# Check if PR_NUMBER is defined via cli flag to avoid call if not needed
if [ -z "$PR_NUMBER" ]; then
    list_prs
fi

prepPrDetails

# Perform the squash merge
squashMergePR "$PR_NUMBER" "$CONV_COMMIT" "$REPO"

# Check the result of squash merge
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Pull Request #$PR_NUMBER has been successfully merged.${NC}"
else
    echo -e "${RED}Failed to merge Pull Request #$PR_NUMBER. Please check the error message above and try again.${NC}"
    exit 1
fi

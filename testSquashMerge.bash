#!/bin/bash

# Enhanced PR Test Script for testing PR generation with edge cases

# Set GPG_TTY
GPG_TTY=$(tty)
export GPG_TTY

# Valid types and scopes for conventional commits
VALID_TYPES=("build" "chore" "ci" "docs" "feat" "fix" "perf" "refactor" "style" "test")
VALID_SCOPES=("dev" "comp" "lib" "fd2" "examples" "school" "none")
COAUTHORS=(
    "Grant Braught <braught@dickinson.edu>"
    "John MacCormick <jmac@dickinson.edu>"
    "William Goble <goblew@dickinson.edu>"
    "Matt Ferland <ferlandm@dickinson.edu>"
    "Boosung Kim <kimbo@dickinson.edu>"
    "Ty Chermsirivatana <chermsit@dickinson.edu>"
)

# Helper functions
get_random_element() {
    local -n array=$1
    echo "${array[RANDOM % ${#array[@]}]}"
}

get_random_invalid() {
    local invalid_values=("invalid" "unknown" "test123" "custom" "random" "xyz")
    echo "${invalid_values[RANDOM % ${#invalid_values[@]}]}"
}

generate_title() {
    local title="$1"
    local rand_types="$2"
    local invalid_type="$3"
    local invalid_scope="$4"
    local no_type="$5"
    local no_scope="$6"

    if [ "$no_type" = true ]; then
        echo "$title"
        return
    fi

    if [ "$rand_types" = true ]; then
        type=$(get_random_invalid)
        scope=$(get_random_invalid)
    else
        if [ "$invalid_type" = true ]; then
            type=$(get_random_invalid)
        else
            type=$(get_random_element VALID_TYPES)
        fi

        if [ "$invalid_scope" = true ]; then
            scope=$(get_random_invalid)
        else
            scope=$(get_random_element VALID_SCOPES)
        fi
    fi

    if [ "$no_scope" != true ]; then
        scope="($scope)"
    else
        scope=""
    fi

    echo "${type}${scope}: ${title}"
}

create_pr() {
    local case="$1"
    local title="$2"
    local body="$3"
    local rand_coauthors="$4"
    local rand_types="$5"
    local invalid_type="${6:-false}"
    local invalid_scope="${7:-false}"
    local no_type="${8:-false}"
    local no_scope="${9:-false}"

    local branch="test-case-${case}-$(date +%s)"
    local pr_title=$(generate_title "$title" "$rand_types" "$invalid_type" "$invalid_scope" "$no_type" "$no_scope")

    # Case-specific modifications for "BREAKING CHANGE" or co-authors
    case "$case" in
        1)
            body="$body

BREAKING CHANGE: This is a breaking change in the PR description."
            ;;
        2)
            ;;
        3)
            body="$body

BREAKING CHANGE: This is a breaking change in the PR description."
            ;;
        4)
            if [ "$rand_coauthors" = true ]; then
                random_coauthor=$(get_random_element COAUTHORS)
                body="$body

Co-authored-by: ${random_coauthor}"
            else
                body="$body

Co-authored-by: ${COAUTHORS[0]}"
            fi
            ;;
        5)
            ;;
        6)
            if [ "$rand_coauthors" = true ]; then
                random_coauthor="${COAUTHORS[RANDOM % ${#COAUTHORS[@]}]}"
                body="$body

Co-authored-by: ${random_coauthor}"
            else
                body="$body

Co-authored-by: ${COAUTHORS[1]}"
            fi
            ;;
    esac

    echo "Creating PR test case ${case}: ${pr_title}"
    echo "Purpose: ${body}"

    git checkout main && git pull && git checkout -b "$branch"
    mkdir -p "test_case_${case}" && echo "Change for: $pr_title" >> "test_case_${case}/testfile.txt"
    git add "test_case_${case}" && git commit -m "$(generate_title "Initial commit" "$rand_types" "$invalid_type" "$invalid_scope" "$no_type" "$no_scope")"

    # Additional commit message customization for specific cases
    case "$case" in
        2)
            git add . && git commit -m "feat(docs): breaking change

BREAKING CHANGE: Commit only breaking change"
            ;;
        3)
            git add . && git commit -m "feat(docs): breaking change

BREAKING CHANGE: Commit breaking change"
            ;;
        5)
            if [ "$rand_coauthors" = true ]; then
                random_coauthor=$(get_random_element COAUTHORS)
                git add . && git commit -m "feat(docs): co-author test

Co-authored-by: ${random_coauthor}"
            else
                git add . && git commit -m "feat(docs): co-author test

Co-authored-by: ${COAUTHORS[0]}"
            fi
            ;;
        6)
            if [ "$rand_coauthors" = true ]; then
                random_coauthor=$(get_random_element COAUTHORS)
                git add . && git commit -m "feat(docs): co-author test

Co-authored-by: ${random_coauthor}"
            else
                git add . && git commit -m "feat(docs): co-author test

Co-authored-by: ${COAUTHORS[1]}"
            fi
            ;;
    esac

    git push -u origin "$branch" && pr_url=$(gh pr create --title "$pr_title" --body "$body")
    echo "Created PR: $pr_url"
    git checkout main
}

run_selected_tests() {
    local selected_cases=(${1//,/ })
    local random_coauthors="$2"
    local random_types="$3"

    for case in "${selected_cases[@]}"; do
        case "$case" in
            1) create_pr "1" "Breaking change in PR description only" "Testing breaking change in PR description only." "$random_coauthors" "$random_types" false false false false ;;
            2) create_pr "2" "Breaking change only in commit message" "Testing breaking change in commit message only." "$random_coauthors" "$random_types" false false false false ;;
            3) create_pr "3" "Breaking changes in both PR and commits" "Testing breaking changes in both locations." "$random_coauthors" "$random_types" false false false false ;;
            4) create_pr "4" "Co-author only in PR description" "Testing co-author in PR description only." "$random_coauthors" "$random_types" false false false false ;;
            5) create_pr "5" "Co-author only in commit message" "Testing co-author in commit message only." "$random_coauthors" "$random_types" false false false false ;;
            6) create_pr "6" "Co-authors in both PR and commits" "Testing co-authors in both locations." "$random_coauthors" "$random_types" false false false false ;;
            7) create_pr "7" "Invalid type and scope test" "Testing invalid type and scope." "$random_coauthors" "$random_types" true true false false ;;
            8) create_pr "8" "Missing type and scope test" "Testing missing type and scope." "$random_coauthors" "$random_types" false false true true ;;
            9) create_pr "9" "Test invalid type" "This PR has an invalid type." "$random_coauthors" "$random_types" true false false false ;;
            10) create_pr "10" "Test invalid scope" "This PR has an invalid scope." "$random_coauthors" "$random_types" false true false false ;;
            11) create_pr "11" "Add new feature without type" "Testing missing type in commit title." "$random_coauthors" "$random_types" false false true false ;;
            12) create_pr "12" "Add feature without scope" "Testing missing scope in commit title." "$random_coauthors" "$random_types" false false false true ;;
            13) create_pr "13" "Empty title test" "" "This PR has no description in the title." "$random_coauthors" "$random_types" false false false false ;;
            14) create_pr "14" "Very long title exceeding usual length" "Testing long title in PR." "$random_coauthors" "$random_types" false false false false ;;
            15) create_pr "15" "Special characters (!@#$%^&*())" "Testing special characters in PR title." "$random_coauthors" "$random_types" false false false false ;;
            *) echo "Invalid test case number: $case" ;;
        esac
    done
}

reset_all_test_cases() {
    echo "Resetting all test cases..."

    # Switch to main branch and pull latest changes
    git checkout main || { echo "Failed to switch to main branch"; return; }
    git pull

    # Delete local branches matching pattern "test-case-*"
    for branch in $(git branch --list "test-case-*"); do
        git branch -D "$branch" || true  # Ignore if branch doesn't exist locally
    done

    # Delete remote branches matching pattern "test-case-*"
    for branch in $(git branch -r | grep "origin/test-case-" | sed 's/origin\///'); do
        git push origin --delete "$branch" || true  # Ignore if branch doesn't exist remotely
    done

    # Remove test case directories
    rm -rf test_case_* || true  # Ignore if directories do not exist

    echo "All test cases have been reset."
}

display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help          Display help"
    echo "  -r, --reset         Reset all test cases"
    echo "  -a, --all           Run all test cases"
    echo "  -s, --select CASES  Run specific test cases (comma-separated list, e.g., 1 or 2,3,4)"
    echo "  -R, --random        Run with random co-authors"
    echo "  -T, --types         Run with random types/scopes"
    echo "  --full-random       Run with random co-authors and types"
}

main() {
    [[ $# -eq 0 ]] && display_help && exit 1
    local random_coauthors=false
    local random_types=false
    local selected_cases="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) display_help; exit 0 ;;
            -r|--reset) reset_all_test_cases; exit 0 ;;
            -a|--all) selected_cases="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15" ;;
            -s|--select) selected_cases="$2"; shift ;;
            -R|--random) random_coauthors=true ;;
            -T|--types) random_types=true ;;
            --full-random) random_coauthors=true; random_types=true ;;
            *) echo "Unknown option: $1"; display_help; exit 1 ;;
        esac
        shift
    done

    if [ -n "$selected_cases" ]; then
        run_selected_tests "$selected_cases" "$random_coauthors" "$random_types"
    else
        echo "No test cases selected. Use -a for all or -s to specify cases."
    fi
}

main "$@"

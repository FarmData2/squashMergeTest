#!/bin/bash

# Test script for squashMergePR.bash
# Tests various combinations of breaking changes, co-authors, types, and scopes

# Set GPG_TTY
GPG_TTY=$(tty)
export GPG_TTY

# Valid types and scopes for conventional commits
VALID_TYPES=("build" "chore" "ci" "docs" "feat" "fix" "perf" "refactor" "style" "test")
VALID_SCOPES=("dev" "comp" "lib" "fd2" "examples" "school" "none")

# Array of co-authors
coauthors=("chermsit@dickinson.edu", "braught@dickinson.edu", "jmac@dickinson.edu", "goblew@dickinson.edu", "ferlandm@dickinson.edu", "kimbo@dickinson.edu")

# Function to get a random co-author
get_random_coauthor() {
    echo "${coauthors[$RANDOM % ${#coauthors[@]}]}"
}

# Function to get a random type
get_random_type() {
    echo "${VALID_TYPES[$RANDOM % ${#VALID_TYPES[@]}]}"
}

# Function to get a random scope
get_random_scope() {
    echo "${VALID_SCOPES[$RANDOM % ${#VALID_SCOPES[@]}]}"
}

# Function to generate a conventional commit title
generate_title() {
    local base_title="$1"
    local use_random="$2"
    local type=""
    local scope=""
    
    if [ "$use_random" = true ]; then
        type=$(get_random_type)
        if [ $((RANDOM % 2)) -eq 0 ]; then  # 50% chance to include scope
            scope="($(get_random_scope))"
        fi
    else
        type="test"
        scope="(test)"
    fi
    
    echo "${type}${scope}: ${base_title}"
}

# Function to create a PR with enhanced testing capabilities
create_pr() {
    local test_case="$1"
    local base_title="$2"
    local body="$3"
    local random_coauthors="$4"
    local random_types="$5"
    local branch_name="test-case-${test_case}-$(date +%s)"
    
    local title=$(generate_title "$base_title" "$random_types")
    
    echo "Creating test case ${test_case}: ${title}"
    echo "Purpose: ${body}"
    
    git checkout main
    git pull
    git checkout -b "$branch_name"
    
    mkdir -p "test_case_${test_case}"
    
    # Initial commit
    echo "Initial test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local initial_title=$(generate_title "Initial commit" "$random_types")
    git commit -m "$initial_title"
    
    # Second commit with co-author
    echo "Second test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local coauthor=$([ "$random_coauthors" = true ] && get_random_coauthor || echo "${coauthors[0]}")
    local second_title=$(generate_title "Second commit" "$random_types")
    git commit -m "$second_title" -m "Co-authored-by: Co-Author <$coauthor>"
    
    # Third commit with co-author and breaking change
    echo "Third test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local coauthor=$([ "$random_coauthors" = true ] && get_random_coauthor || echo "${coauthors[1]}")
    local third_title=$(generate_title "Third commit" "$random_types")
    git commit -m "$third_title" -m "BREAKING CHANGE: This commit introduces a breaking change." -m "Co-authored-by: Co-Author <$coauthor>"
    
    git push -u origin "$branch_name"
    
    # Create PR
    pr_url=$(gh pr create --title "$title" --body "$body")
    echo "Created PR for test case $test_case: $pr_url"
    echo "----------------------------------------"

    git checkout main
}

# Function to delete a branch both locally and remotely
delete_branch() {
    local branch_name="$1"
    git branch -D "$branch_name" 2>/dev/null
    git push origin --delete "$branch_name" 2>/dev/null
}

# Function to remove test case directories
remove_test_case_dirs() {
    for dir in test_case_*; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            echo "Removed directory: $dir"
        fi
    done
}

# Function to reset all test cases
reset_all() {
    echo "Resetting all test cases..."
    git checkout main
    git pull
    
    for branch in $(git branch --list "test-case-*"); do
        delete_branch "$branch"
        echo "Deleted branch: $branch"
    done
    
    remove_test_case_dirs
    echo "All test cases have been reset."
}

# Combination of breaking changes and co authors (for Prof. Braught)
create_verbose_edge_case() {
    local test_case="$1"
    local random_coauthors="$2"
    local random_types="$3"
    local branch_name="test-case-${test_case}-$(date +%s)"
    
    echo "Creating verbose edge case test..."
    echo "Testing multiple combinations of breaking changes and co-authors"
    
    git checkout main
    git pull
    git checkout -b "$branch_name"
    
    mkdir -p "test_case_${test_case}"
    
    # Generate random or test type/scope for PR title
    local title=$(generate_title "Comprehensive edge case test [BREAKING CHANGE]" "$random_types")
    
    # Create complex commit history with various formats and combinations
    
    # Commit 1: Standard commit with co-author
    echo "First change" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local commit1_title=$(generate_title "Initial commit with co-author" "$random_types")
    git commit -m "$commit1_title" \
              -m "This is a standard commit with a co-author." \
              -m "Co-authored-by: First Author <${coauthors[0]}>"
    
    # Commit 2: Breaking change with different format and multiple co-authors
    echo "Second change" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local commit2_title=$(generate_title "Second commit with breaking change" "$random_types")
    git commit -m "$commit2_title" \
              -m "BREAKING-CHANGE: Testing hyphenated format" \
              -m "This is a multiline commit message" \
              -m "with multiple paragraphs" \
              -m "Co-authored-by: Second Author <${coauthors[1]}>" \
              -m "Co-authored-by: Third Author <${coauthors[2]}>"
    
    # Commit 3: Multiple breaking changes with varying formats
    echo "Third change" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local commit3_title=$(generate_title "Third commit with multiple breaks" "$random_types")
    git commit -m "$commit3_title" \
              -m "BREAKING CHANGE: First breaking change" \
              -m "Breaking Change: Second breaking change with different format" \
              -m "BREAKING-CHANGE: Third breaking change with hyphen" \
              -m "This tests multiple breaking change formats in one commit"
    
    # Commit 4: Duplicate co-authors and breaking change
    echo "Fourth change" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local commit4_title=$(generate_title "Fourth commit with duplicates" "$random_types")
    git commit -m "$commit4_title" \
              -m "BREAKING CHANGE: Testing duplicate co-authors" \
              -m "Co-authored-by: First Author <${coauthors[0]}>" \
              -m "Co-authored-by: First Author <${coauthors[0]}>" \
              -m "Co-authored-by: Second Author <${coauthors[1]}>"
    
    # Commit 5: Special characters in breaking change and co-author
    echo "Fifth change" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local commit5_title=$(generate_title "Fifth commit with special chars" "$random_types")
    git commit -m "$commit5_title" \
              -m "BREAKING CHANGE: Testing special characters: !@#$%^&*()" \
              -m "Co-authored-by: Special Author !@#$ <${coauthors[3]}>"
    
    git push -u origin "$branch_name"
    
    # Create PR with comprehensive body including all edge cases
    local pr_body="Comprehensive edge case test for breaking changes and co-authors

# Breaking Changes
BREAKING CHANGE: Major API change with multiple paragraphs
This is a detailed explanation of the breaking change
that spans multiple lines

BREAKING-CHANGE: Testing hyphenated format
Breaking Change: Testing different capitalization
BREAKING CHANGE: Testing with special characters !@#$%^&*()

# Co-Authors
This PR includes multiple co-authors in different formats:
Co-authored-by: First Author <${coauthors[0]}>
Co-authored-by: Second Author <${coauthors[1]}>
Co-authored-by: First Author <${coauthors[0]}> (Duplicate)
Co-authored-by: Special !@#$ Author <${coauthors[3]}>

# Test Cases Covered
1. Multiple breaking changes in different formats
2. Breaking changes with special characters
3. Breaking changes with multiple paragraphs
4. Duplicate co-authors
5. Co-authors with special characters
6. Mixed case formats for breaking changes
7. Multiple co-authors in single commit
8. Breaking change markers in commit messages and PR body
9. Breaking change marker in PR title
10. Various conventional commit types and scopes

# Additional Edge Cases
- Empty lines between breaking changes
- Special characters in commit messages
- Duplicate information in commits and PR body
- Mixed formatting and line endings
- Unicode characters: ★☆♠♣♥♦
- Emoji in text: 🚀 💥 🔨 🐛"

    pr_url=$(gh pr create --title "$title" --body "$pr_body")
    echo "Created verbose edge case PR: $pr_url"
    echo "----------------------------------------"

    git checkout main
}

# Function to run all test cases
run_all_tests() {
    local random_coauthors="$1"
    local random_types="$2"
    
    echo "Running all test cases..."
    echo "Using random types and scopes: $random_types"
    echo "Using random co-authors: $random_coauthors"
    echo "----------------------------------------"

    # Test Case 1: Breaking change in PR body only
    create_pr "1" "Breaking change only in PR description" \
        "Testing breaking change in PR description only.
BREAKING CHANGE: This is a breaking change in the PR description." "$random_coauthors" "$random_types"

    # Test Case 2: Breaking change in commit only
    create_pr "2" "Breaking change only in commit message" \
        "Testing breaking change in commit message only." "$random_coauthors" "$random_types"

    # Test Case 3: Breaking changes in both PR and commits
    create_pr "3" "Breaking changes in both PR and commits" \
        "Testing breaking changes in both locations.
BREAKING CHANGE: This is a breaking change in the PR description." "$random_coauthors" "$random_types"

    # Test Case 4: Co-author in PR body only
    create_pr "4" "Co-author only in PR description" \
        "Testing co-author in PR description only.
Co-authored-by: Co-Author <${coauthors[0]}>" "$random_coauthors" "$random_types"

    # Test Case 5: Co-author in commit only
    create_pr "5" "Co-author only in commit message" \
        "Testing co-author in commit message only." "$random_coauthors" "$random_types"

    # Test Case 6: Co-authors in both PR and commits
    create_pr "6" "Co-authors in both PR and commits" \
        "Testing co-authors in both locations.
Co-authored-by: Co-Author <${coauthors[0]}>" "$random_coauthors" "$random_types"

    # Test Case 7: Multiple breaking changes and co-authors
    create_pr "7" "Multiple breaking changes and co-authors" \
        "Testing multiple breaking changes and co-authors.
BREAKING CHANGE: First breaking change in PR.
BREAKING CHANGE: Second breaking change in PR.
Co-authored-by: Co-Author 1 <${coauthors[0]}>
Co-authored-by: Co-Author 2 <${coauthors[1]}>" "$random_coauthors" "$random_types"

    # Test Case 8: Breaking change in title and body
    create_pr "8" "Breaking change marker in title [BREAKING CHANGE]" \
        "Testing breaking change marker in both title and body.
BREAKING CHANGE: This is a breaking change in the PR description." "$random_coauthors" "$random_types"

    # Test Case 9: Invalid type and scope
    create_pr "9" "Invalid type and scope test" \
        "Testing with invalid type and scope.
Co-authored-by: Co-Author <${coauthors[0]}>" "$random_coauthors" false

    # Test Case 10: Missing type and scope
    create_pr "10" "Missing type and scope test" \
        "Testing with missing type and scope." "$random_coauthors" false 
    
    # Test Case 11: Verbose edge case
    create_verbose_edge_case "11" "$random_coauthors" "$random_types"
}

# Function to display help menu
display_help() {
    echo "Enhanced PR Test Script"
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help     Display this help message"
    echo "  -r, --reset    Reset all test cases"
    echo "  -a, --all      Run all test cases"
    echo "  -s, --select   Select specific test cases to run"
    echo "  -R, --random   Run test cases with random co-authors"
    echo "  -T, --types    Run test cases with random types and scopes"
    echo "  --full-random  Run test cases with both random co-authors and types/scopes"
    echo ""
    echo "Valid Types: ${VALID_TYPES[*]}"
    echo "Valid Scopes: ${VALID_SCOPES[*]}"
    echo ""
    echo "Test Cases:"
    echo "1. Breaking change in PR description only"
    echo "2. Breaking change in commit message only"
    echo "3. Breaking changes in both PR and commits"
    echo "4. Co-author in PR description only"
    echo "5. Co-author in commit message only"
    echo "6. Co-authors in both PR and commits"
    echo "7. Multiple breaking changes and co-authors"
    echo "8. Breaking change marker in title and body"
    echo "9. Invalid type and scope test"
    echo "10. Missing type and scope test"
    echo "11. Verbose edge case (comprehensive test of all combinations)"
}

# Function to select and run specific test cases
select_and_run_tests() {
    local random_coauthors="$1"
    local random_types="$2"
    
    echo "Select test cases to run (enter numbers separated by spaces):"
    display_help
    
    read -p "Enter your selection: " selection
    
    for case in $selection; do
        case $case in
            1|2|3|4|5|6|7|8|9|10)
                run_specific_test_case "$case" "$random_coauthors" "$random_types"
                ;;
            *)
                echo "Invalid test case number: $case"
                ;;
        esac
    done
}

# Function to run a specific test case
run_specific_test_case() {
    local case="$1"
    local random_coauthors="$2"
    local random_types="$3"
    
    # Call run_all_tests with a filter for the specific case
    local test_filter="$case"
    run_all_tests "$random_coauthors" "$random_types" "$test_filter"
}

# Main script
main() {
    if [ $# -eq 0 ]; then
        display_help
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                display_help
                exit 0
                ;;
            -r|--reset)
                reset_all
                exit 0
                ;;
            -a|--all)
                run_all_tests false false
                exit 0
                ;;
            -s|--select)
                select_and_run_tests false false
                exit 0
                ;;
            -R|--random)
                run_all_tests true false
                exit 0
                ;;
            -T|--types)
                run_all_tests false true
                exit 0
                ;;
            --full-random)
                run_all_tests true true
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                display_help
                exit 1
                ;;
        esac
        shift
    done
}

main "$@"
#!/bin/bash

# Test script for squashMergePR.bash by Ty Chermsirivatana

# Set GPG_TTY
GPG_TTY=$(tty)
export GPG_TTY

# Array of co-authors
coauthors=("chermsit@dickinson.edu", "braught@dickinson.edu" "jmac@dickinson.edu" "goblew@dickinson.edu" "ferlandm@dickinson.edu" "kimbo@dickinson.edu")

# Function to get a random co-author
get_random_coauthor() {
    echo "${coauthors[$RANDOM % ${#coauthors[@]}]}"
}

# Function to create a PR
create_pr() {
    local test_case="$1"
    local title="$2"
    local body="$3"
    local random_coauthors="$4"
    local branch_name="test-case-${test_case}-$(date +%s)"
   
    git checkout main
    git pull
    git checkout -b "$branch_name"
   
    mkdir -p "test_case_${test_case}"
   
    # Initial commit
    echo "Initial test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Initial commit for: $title"
   
    # Second commit with random co-author
    echo "Second test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local coauthor=$([ "$random_coauthors" = true ] && get_random_coauthor || echo "${coauthors[0]}")
    git commit -m "Second commit for: $title" -m "Co-authored-by: Co-Author <$coauthor>"
   
    # Third commit with another random co-author and breaking change
    echo "Third test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local coauthor=$([ "$random_coauthors" = true ] && get_random_coauthor || echo "${coauthors[1]}")
    git commit -m "Third commit for: $title" -m "BREAKING CHANGE: This commit introduces a breaking change." -m "Co-authored-by: Co-Author <$coauthor>"
   
    # Fourth commit with breaking change
    echo "Fourth test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Fourth commit for: $title" -m "BREAKING CHANGE: This commit introduces another breaking change."
   
    # Fifth commit with breaking change and possibly duplicate co-author
    echo "Fifth test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    local coauthor=$([ "$random_coauthors" = true ] && get_random_coauthor || echo "${coauthors[0]}")
    git commit -m "Fifth commit for: $title" -m "BREAKING CHANGE: This commit introduces yet another breaking change. I just want to make sure it handles multiline breaks!" -m "Co-authored-by: Co-Author <$coauthor>"
   
    git push -u origin "$branch_name"
   
    # Create PR with only the original body
    pr_url=$(gh pr create --title "$title" --body "$body" --head "$branch_name")
    echo "Created PR for test case $test_case: $pr_url"

    # Switch back to main branch
    git checkout main
}

# Function to delete a branch both locally and remotely
delete_branch() {
    local branch_name="$1"
   
    # Delete the branch locally
    git branch -D "$branch_name"
   
    # Delete the branch remotely
    git push origin --delete "$branch_name"
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
    git checkout main
    git pull
   
    # Delete branches
    for branch in $(git branch --list "test-case-*"); do
        delete_branch "$branch"
        echo "Deleted branch: $branch"
    done
   
    # Remove test case directories
    remove_test_case_dirs
   
    echo "All test cases have been reset."
}

# Function to display help menu
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help     Display this help message"
    echo "  -r, --reset    Reset all test cases"
    echo "  -a, --all      Run all test cases"
    echo "  -s, --select   Select specific test cases to run"
    echo "  -R, --random   Run test cases with random co-authors and possible duplicates"
}

# Function to run all test cases
run_all_tests() {
    local random_coauthors="$1"
    create_pr "1" "feat(docs): add new documentation" "This PR adds new documentation.
BREAKING CHANGE: This change breaks the existing API." "$random_coauthors"
    create_pr "2" "invalid(docs): test invalid type" "This PR has an invalid type." "$random_coauthors"
    create_pr "3" "feat(invalid): test invalid scope" "This PR has an invalid scope." "$random_coauthors"
    create_pr "4" "add new feature" "This PR doesn't specify a type." "$random_coauthors"
    create_pr "5" "feat: add new feature without scope" "This PR doesn't specify a scope." "$random_coauthors"
    create_pr "6" "feat(docs):" "This PR has no description in the title." "$random_coauthors"
    create_pr "7" "feat(docs): add breaking change" "This PR adds a breaking change.
BREAKING CHANGE: This changes the API significantly." "$random_coauthors"
    create_pr "8" "feat(docs): multiple breaking changes" "This PR has multiple breaking changes.
BREAKING CHANGE: First breaking change.
BREAKING CHANGE: Second breaking change." "$random_coauthors"
    create_pr "9" "feat(docs): add very long description that exceeds the usual length of a PR title and might cause issues with parsing or display" "This PR has a very long description in the title." "$random_coauthors"
    create_pr "10" "feat(docs): add special characters (!@#$%^&*())" "This PR has special characters in the description." "$random_coauthors"
}

# Function to select and run specific test cases
select_and_run_tests() {
    local random_coauthors="$1"
    echo "Select test cases to run (enter numbers separated by spaces, e.g., '1 3 5'):"
    echo "1. New documentation with breaking change"
    echo "2. Invalid type"
    echo "3. Invalid scope"
    echo "4. Missing type"
    echo "5. Missing scope"
    echo "6. Missing description in title"
    echo "7. Breaking change"
    echo "8. Multiple breaking changes"
    echo "9. Very long description"
    echo "10. Special characters"
    
    read -p "Enter your selection: " selection
    
    for case in $selection; do
        case $case in
            1) create_pr "1" "feat(docs): add new documentation" "This PR adds new documentation.
BREAKING CHANGE: This change breaks the existing API." "$random_coauthors" ;;
            2) create_pr "2" "invalid(docs): test invalid type" "This PR has an invalid type." "$random_coauthors" ;;
            3) create_pr "3" "feat(invalid): test invalid scope" "This PR has an invalid scope." "$random_coauthors" ;;
            4) create_pr "4" "add new feature" "This PR doesn't specify a type." "$random_coauthors" ;;
            5) create_pr "5" "feat: add new feature without scope" "This PR doesn't specify a scope." "$random_coauthors" ;;
            6) create_pr "6" "feat(docs):" "This PR has no description in the title." "$random_coauthors" ;;
            7) create_pr "7" "feat(docs): add breaking change" "This PR adds a breaking change.
BREAKING CHANGE: This changes the API significantly." "$random_coauthors" ;;
            8) create_pr "8" "feat(docs): multiple breaking changes" "This PR has multiple breaking changes.
BREAKING CHANGE: First breaking change.
BREAKING CHANGE: Second breaking change." "$random_coauthors" ;;
            9) create_pr "9" "feat(docs): add very long description that exceeds the usual length of a PR title and might cause issues with parsing or display" "This PR has a very long description in the title." "$random_coauthors" ;;
            10) create_pr "10" "feat(docs): add special characters (!@#$%^&*())" "This PR has special characters in the description." "$random_coauthors" ;;
            *) echo "Invalid test case number: $case" ;;
        esac
    done
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
                run_all_tests false
                exit 0
                ;;
            -s|--select)
                select_and_run_tests false
                exit 0
                ;;
            -R|--random)
                run_all_tests true
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
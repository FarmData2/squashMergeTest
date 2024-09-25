#!/bin/bash


GPG_TTY=$(tty)
export GPG_TTY


coauthors=("chermsit@dickinson.edu" "braught@dickinson.edu" "jmac@dickinson.edu" "goblew@dickinson.edu" "ferlandm@dickinson.edu")

# Function to get a random co-author
get_random_coauthor() {
    echo "${coauthors[$RANDOM % ${#coauthors[@]}]}"
}

create_pr() {
    local test_case="$1"
    local title="$2"
    local body="$3"
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
    git commit -m "Second commit for: $title" --author="Co-Author <$(get_random_coauthor)>"
    
    # Third commit with another random co-author
    echo "Third test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Third commit for: $title" --author="Co-Author <$(get_random_coauthor)>"
    
    # Fourth commit with breaking change
    echo "Fourth test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Fourth commit for: $title\n\nBREAKING CHANGE: This commit introduces a breaking change."

    # Fifth commit with breaking change
    echo "Fifth test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Fifth commit for: $title\n\nBREAKING CHANGE: This commit introduces another breaking change."
    
    git push -u origin "$branch_name"
    
    pr_url=$(gh pr create --title "$title" --body "$body" --head "$branch_name")
    echo "Created PR for test case $test_case: $pr_url"
}

# Test cases
create_pr "1" "feat(docs): add new documentation" "This PR adds new documentation.
BREAKING CHANGE: This change breaks the existing API."

create_pr "2" "invalid(docs): test invalid type" "This PR has an invalid type."

create_pr "3" "feat(invalid): test invalid scope" "This PR has an invalid scope."

create_pr "4" "add new feature" "This PR doesn't specify a type."

create_pr "5" "feat: add new feature without scope" "This PR doesn't specify a scope."

create_pr "6" "feat(docs):" "This PR has no description in the title."

create_pr "7" "feat(docs): add breaking change" "This PR adds a breaking change.
BREAKING CHANGE: This changes the API significantly."

create_pr "8" "feat(docs): multiple breaking changes" "This PR has multiple breaking changes.
BREAKING CHANGE: First breaking change.
BREAKING CHANGE: Second breaking change."

create_pr "9" "feat(docs): add very long description that exceeds the usual length of a PR title and might cause issues with parsing or display" "This PR has a very long description in the title."

create_pr "10" "feat(docs): add special characters (!@#$%^&*())" "This PR has special characters in the description."



git switch main
echo "All test PRs have been created."
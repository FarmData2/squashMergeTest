#!/bin/bash

GPG_TTY=$(tty)
export GPG_TTY

# Array of co-authors
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
    git commit -m "Second commit for: $title" -m "Co-authored-by: Co-Author <$(get_random_coauthor)>"
   
    # Third commit with another random co-author and breaking change
    echo "Third test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Third commit for: $title" -m "BREAKING CHANGE: This commit introduces a breaking change." -m "Co-authored-by: Co-Author <$(get_random_coauthor)>"
   
    # Fourth commit with breaking change
    echo "Fourth test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Fourth commit for: $title" -m "BREAKING CHANGE: This commit introduces another breaking change."
   
    # Fifth commit with breaking change
    echo "Fifth test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Fifth commit for: $title" -m "BREAKING CHANGE: This commit introduces yet another breaking change."
   
    git push -u origin "$branch_name"
   
    # Create PR with only the original body
    pr_url=$(gh pr create --title "$title" --body "$body" --head "$branch_name")
    echo "Created PR for test case $test_case: $pr_url"
}

# Single test case
create_pr "1" "feat(docs): add new documentation" "This PR adds new documentation."
echo "Test PR has been created."
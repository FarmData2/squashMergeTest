#!/bin/bash

# You know, I read the issue, saw the comment about avoiding merge conflicts, rushed in, had merge conflicts, fair play.

create_pr() {
    local test_case="$1"
    local title="$2"
    local body="$3"
    local branch_name="test-case-${test_case}-$(date +%s)"
    
    git checkout main 
    git pull
    git checkout -b "$branch_name"
    
    mkdir -p "test_case_${test_case}"
    echo "Test change for: $title" >> "test_case_${test_case}/testfile.txt"
    git add "test_case_${test_case}"
    git commit -m "Test commit for: $title"
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

echo "All test PRs have been created."

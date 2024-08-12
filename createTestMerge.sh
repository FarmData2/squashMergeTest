#!/bin/bash

create_pr() {
    local title="$1"
    local body="$2"
    local branch_name="test-$(date +%s)"

    git checkout -b "$branch_name"

    echo "Test change for: $title" >> testfile.txt

    git add testfile.txt
    git commit -m "Test commit for: $title"

    git push -u origin "$branch_name"

    pr_url=$(gh pr create --title "$title" --body "$body" --head "$branch_name")

    echo "Created PR: $pr_url"
}

# Test cases

# 1. Valid conventional commit format
create_pr "feat(docs): add new documentation" "This PR adds new documentation.

BREAKING CHANGE: This change breaks the existing API."

# 2. Invalid type
create_pr "invalid(docs): test invalid type" "This PR has an invalid type."

# 3. Invalid scope
create_pr "feat(invalid): test invalid scope" "This PR has an invalid scope."

# 4. No type
create_pr "add new feature" "This PR doesn't specify a type."

# 5. No scope
create_pr "feat: add new feature without scope" "This PR doesn't specify a scope."

# 6. No description after type and scope
create_pr "feat(docs):" "This PR has no description in the title."

# 7. Breaking change in body without indicator in title
create_pr "feat(docs): add breaking change" "This PR adds a breaking change.

BREAKING CHANGE: This changes the API significantly."

# 8. Multiple breaking changes
create_pr "feat(docs): multiple breaking changes" "This PR has multiple breaking changes.

BREAKING CHANGE: First breaking change.
BREAKING CHANGE: Second breaking change."

# 9. Long description
create_pr "feat(docs): add very long description that exceeds the usual length of a PR title and might cause issues with parsing or display" "This PR has a very long description in the title."

# 10. Special characters in description
create_pr "feat(docs): add special characters (!@#$%^&*())" "This PR has special characters in the description."

echo "All test PRs have been created."

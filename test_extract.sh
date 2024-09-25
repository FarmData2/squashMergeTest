#!/bin/bash

PR_URL="https://github.com/FarmData2/squashMergeTest/pull/43"
PR_NUMBER=$(echo $PR_URL | grep -oP '(?<=pull/)\d+')

echo "Fetching commits for PR #$PR_NUMBER..."


commit_shas=$(gh pr view $PR_NUMBER --json commits --jq '.commits[].oid')

echo "Commits found:"


while read -r sha; do
    echo -e "\nCommit: $sha"
    

    commit_details=$(gh api repos/:owner/:repo/commits/$sha)
    

    commit_message=$(echo "$commit_details" | jq -r '.commit.message')
    echo "Message:"
    echo "$commit_message"
    

    breaking_changes=$(echo "$commit_message" | grep -i "BREAKING CHANGE:" | sed 's/BREAKING CHANGE:/Breaking Changes:/')
    if [ ! -z "$breaking_changes" ]; then
        echo "$breaking_changes"
    fi
    

    co_authors=$(echo "$commit_message" | grep -i "Co-authored-by:")
    if [ ! -z "$co_authors" ]; then
        echo "Co-authors:"
        echo "$co_authors"
    fi
done <<< "$commit_shas"

echo -e "\nExtraction complete."
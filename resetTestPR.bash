#!/bin/bash

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

# Main script
main() {
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

main
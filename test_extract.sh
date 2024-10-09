#!/bin/bash

# Function to retrieve user info from GitHub using email or username
retrieve_user_info() {
    local input="$1"
    local user_info=""
    local search_type=""

    # First, try to search by email
    if [[ "$input" == *@* ]]; then
        search_type="email"
        user_info=$(gh api "search/users?q=$input" --jq '.items[0]')
    fi

    # If email search fails or input is not an email, search by username
    if [[ -z "$user_info" ]]; then
        search_type="username"
        user_info=$(gh api "users/$input")
    fi

    # Process and display user information
    if [[ -n "$user_info" ]]; then
        local username=$(echo "$user_info" | jq -r '.login')
        local full_name=$(echo "$user_info" | jq -r '.name')
        local email=$(echo "$user_info" | jq -r '.email')
        
        # Split full name into first and last name
        local first_name=$(echo "$full_name" | awk '{print $1}')
        local last_name=$(echo "$full_name" | awk '{print $NF}')  # Assumes the last word is the last name

        # Output the result
        echo "Search type: $search_type"
        echo "Username: $username"
        echo "First Name: $first_name"
        echo "Last Name: $last_name"
        echo "Email: $email"
    else
        echo "No user found for $search_type: $input"
    fi
}

# Test cases
input_list=("WarpWing" "braughtg" "goblew@dickinson.edu", "wpgoble")

for input in "${input_list[@]}"; do
    echo "Looking up: $input"
    retrieve_user_info "$input"
    echo ""
done
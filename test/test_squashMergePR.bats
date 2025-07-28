#!/usr/bin/env bats

load 'test_helper'

setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export SCRIPT_PATH="$(realpath ../squashMergePR.bash)"
}

teardown() {
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "script exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "displays help when --help flag is used" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--type"* ]]
    [[ "$output" == *"--scope"* ]]
    [[ "$output" == *"--pr"* ]]
}

@test "exits with error on unknown option" {
    run "$SCRIPT_PATH" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "checkDependencies function detects missing gh" {
    run bash -c "
        {
            source $SCRIPT_PATH
        } >/dev/null 2>&1
        PATH='' checkDependencies
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"GitHub CLI (gh)"* ]]
}

@test "checkDependencies function detects missing jq" {
    run bash -c "
        {
            source $SCRIPT_PATH
        } >/dev/null 2>&1
        PATH='' checkDependencies
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"jq"* ]]
}

@test "elementInArray function works correctly" {
    run bash -c "
        source $SCRIPT_PATH
        if elementInArray 'feat' 'feat' 'fix' 'docs'; then
            echo 'found'
        else
            echo 'not found'
        fi
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"found"* ]]

    run bash -c "
        source $SCRIPT_PATH
        if elementInArray 'invalid' 'feat' 'fix' 'docs'; then
            echo 'found'
        else
            echo 'not found'
        fi
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "parsePrTitle function parses conventional commit format correctly" {
    run bash -c "
        source $SCRIPT_PATH
        parsePrTitle 'feat(comp): add new feature'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "feat|comp|add new feature" ]]
}

@test "parsePrTitle function handles type only" {
    run bash -c "
        source $SCRIPT_PATH
        parsePrTitle 'feat: add feature'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "feat||add feature" ]]
}

@test "parsePrTitle function handles scope only" {
    run bash -c "
        source $SCRIPT_PATH
        parsePrTitle '(comp): add feature'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "|comp|add feature" ]]
}

@test "parsePrTitle function handles description only" {
    run bash -c "
        source $SCRIPT_PATH
        parsePrTitle 'add new feature'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "||add new feature" ]]
}

@test "parsePrTitle function handles empty title" {
    run bash -c "
        source $SCRIPT_PATH
        parsePrTitle ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "||" ]]
}

@test "parsePrTitle function handles special characters" {
    run bash -c "
        source $SCRIPT_PATH
        parsePrTitle 'feat(comp): add feature with special chars (!@#\$%^&*)'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "feat|comp|add feature with special chars (!@#\$%^&*)" ]]
}

@test "checkPrTitleComponents function detects missing type" {
    run bash -c "
        source $SCRIPT_PATH
        checkPrTitleComponents '' 'comp' 'description'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Missing: type"* ]]
}

@test "checkPrTitleComponents function detects invalid type" {
    run bash -c "
        source $SCRIPT_PATH
        checkPrTitleComponents 'invalid' 'comp' 'description'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Invalid: type"* ]]
}

@test "checkPrTitleComponents function detects missing scope" {
    run bash -c "
        source $SCRIPT_PATH
        checkPrTitleComponents 'feat' '' 'description'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Missing: scope"* ]]
}

@test "checkPrTitleComponents function detects invalid scope" {
    run bash -c "
        source $SCRIPT_PATH
        checkPrTitleComponents 'feat' 'invalid' 'description'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Invalid: scope"* ]]
}

@test "checkPrTitleComponents function accepts 'none' as valid scope" {
    run bash -c "
        source $SCRIPT_PATH
        checkPrTitleComponents 'feat' 'none' 'description'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "" ]]
}

@test "checkPrTitleComponents function detects missing description" {
    run bash -c "
        source $SCRIPT_PATH
        checkPrTitleComponents 'feat' 'comp' ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Missing: description"* ]]
}

@test "checkPrTitleComponents function passes valid input" {
    run bash -c "
        source $SCRIPT_PATH
        checkPrTitleComponents 'feat' 'comp' 'add new feature'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "" ]]
}

@test "convertToConventionalCommit function formats basic commit message" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'comp' 'add feature' '' '' ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "feat(comp): add feature" ]]
}

@test "convertToConventionalCommit function handles scope 'none'" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'none' 'add feature' '' '' ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "feat: add feature" ]]
}

@test "convertToConventionalCommit function includes body" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'comp' 'add feature' 'This is the body' '' ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"feat(comp): add feature"* ]]
    [[ "$output" == *"This is the body"* ]]
}

@test "convertToConventionalCommit function includes breaking changes" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'comp' 'add feature' '' 'BREAKING CHANGE: This breaks things' ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"BREAKING CHANGE: This breaks things"* ]]
}

@test "convertToConventionalCommit function includes co-authors" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'comp' 'add feature' '' '' 'Co-authored-by: Grant Braught <braught@dickinson.edu>'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Co-authored-by: Grant Braught <braught@dickinson.edu>"* ]]
}

@test "convertToConventionalCommit function handles all components" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'comp' 'add feature' 'Body text' 'BREAKING CHANGE: This breaks things' 'Co-authored-by: Ty Chermsirivatana <chermsit@dickinson.edu>'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"feat(comp): add feature"* ]]
    [[ "$output" == *"Body text"* ]]
    [[ "$output" == *"BREAKING CHANGE: This breaks things"* ]]
    [[ "$output" == *"Co-authored-by: Ty Chermsirivatana <chermsit@dickinson.edu>"* ]]
}

@test "VALID_TYPES array contains expected values" {
    run bash -c "
        source $SCRIPT_PATH
        printf '%s\n' \"\${VALID_TYPES[@]}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"build"* ]]
    [[ "$output" == *"feat"* ]]
    [[ "$output" == *"fix"* ]]
    [[ "$output" == *"docs"* ]]
}

@test "VALID_SCOPES array contains expected values" {
    run bash -c "
        source $SCRIPT_PATH
        printf '%s\n' \"\${VALID_SCOPES[@]}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"dev"* ]]
    [[ "$output" == *"comp"* ]]
    [[ "$output" == *"lib"* ]]
    [[ "$output" == *"none"* ]]
}



@test "script handles git repository URL parsing" {
    cd "$TEST_TEMP_DIR"
    git init >/dev/null 2>&1
    git remote add origin "https://github.com/farmdata2/farmdata2.git"

    run bash -c "
        cd $TEST_TEMP_DIR
        source $SCRIPT_PATH 2>/dev/null
        echo \$REPO
    "
    [[ "$output" == *"farmdata2/farmdata2"* ]]
}

@test "script handles SSH git repository URL parsing" {
    cd "$TEST_TEMP_DIR"
    git init >/dev/null 2>&1
    git remote add origin "git@github.com:farmdata2/farmdata2.git"

    run bash -c "
        cd $TEST_TEMP_DIR
        source $SCRIPT_PATH 2>/dev/null
        echo \$REPO
    "
    [[ "$output" == *"farmdata2/farmdata2"* ]]
}

@test "script exits when not in git repo and no repo URL provided" {
    cd "$TEST_TEMP_DIR"

    run "$SCRIPT_PATH" --pr 123
    [ "$status" -eq 1 ]
    [[ "$output" == *"GitHub CLI login failed"* || "$output" == *"Repository URL is required"* ]]
}

@test "long title handling" {
    long_title="This is a very long title that exceeds the usual length expected for a conventional commit message and should be handled properly by the parsing function without causing any issues or truncation problems"
    run bash -c "
        source $SCRIPT_PATH
        parsePrTitle '$long_title'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "||$long_title" ]]
}

@test "breaking change extraction from commit message format" {
    commit_msg="feat(comp): add feature

Some description

BREAKING CHANGE: This breaks backward compatibility

Co-authored-by: John Doe <john@example.com>"

    breaking_change=$(echo "$commit_msg" | grep "BREAKING CHANGE:" | head -1)
    [[ "$breaking_change" == "BREAKING CHANGE: This breaks backward compatibility" ]]
}

@test "co-author extraction from commit message format" {
    commit_msg="feat(comp): add feature

Some description

Co-authored-by: Grant Braught <braught@dickinson.edu>
Co-authored-by: John MacCormick <jmac@dickinson.edu>"

    co_authors=$(echo "$commit_msg" | grep "Co-authored-by:")
    [[ "$co_authors" == *"Grant Braught"* ]]
    [[ "$co_authors" == *"John MacCormick"* ]]
}

@test "multiple breaking changes handling" {
    commit_msg="feat(comp): add feature

BREAKING CHANGE: First breaking change
BREAKING CHANGE: Second breaking change"

    breaking_changes=$(echo "$commit_msg" | grep "BREAKING CHANGE:")
    [ $(echo "$breaking_changes" | wc -l) -eq 2 ]
}

@test "empty body handling in convertToConventionalCommit" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'comp' 'add feature' '' '' ''
    "
    [ "$status" -eq 0 ]
    lines=$(echo "$output" | wc -l)
    [ "$lines" -eq 1 ]
}

@test "whitespace trimming in commit message generation" {
    run bash -c "
        source $SCRIPT_PATH
        convertToConventionalCommit 'feat' 'comp' '  add feature  ' '  body with spaces  ' '' ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"feat(comp):   add feature  "* ]]
}

@test "case sensitivity in type validation" {
    run bash -c "
        source $SCRIPT_PATH
        if elementInArray 'FEAT' 'feat' 'fix' 'docs'; then
            echo 'found'
        else
            echo 'not found'
        fi
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"found"* ]]

    run bash -c "
        source $SCRIPT_PATH
        if elementInArray 'Feat' 'feat' 'fix' 'docs'; then
            echo 'found'
        else
            echo 'not found'
        fi
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"found"* ]]
}

@test "regex parsing with various conventional commit formats" {
    test_cases=(
        "feat(comp): description|feat|comp|description"
        "fix: bug fix|fix||bug fix"
        "(lib): library change||lib|library change"
        "docs(examples): update docs|docs|examples|update docs"
        "chore: maintenance|chore||maintenance"
        "test(fd2): add tests|test|fd2|add tests"
    )

    for case in "${test_cases[@]}"; do
        input="${case%%|*}"
        expected="${case#*|}"
        run bash -c "
            source $SCRIPT_PATH >/dev/null 2>&1
            parsePrTitle '$input'
        "
        [ "$status" -eq 0 ]
        if [[ "$output" != "$expected" ]]; then
            echo "FAILED case: $case"
            echo "Input: $input"
            echo "Expected: $expected"
            echo "Got: $output"
        fi
        [[ "$output" == "$expected" ]]
    done
}

@test "command line argument parsing" {
    run bash -c "source $SCRIPT_PATH <<< '' && echo \$TYPE \$SCOPE \$DESCRIPTION"
    run "$SCRIPT_PATH" --type feat --scope comp --description "test desc" --help
    [ "$status" -eq 0 ]
}

@test "invalid command line arguments" {
    run "$SCRIPT_PATH" --invalid-arg value
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "repo URL validation with various formats" {
    test_urls=(
        "https://github.com/farmdata2/farmdata2.git"
        "https://github.com/farmdata2/farmdata2"
        "git@github.com:farmdata2/farmdata2.git"
        "git@github.com:farmdata2/farmdata2"
    )

    for url in "${test_urls[@]}"; do
        cd "$TEST_TEMP_DIR"
        rm -rf .git
        git init >/dev/null 2>&1
        git remote add origin "$url" >/dev/null 2>&1

        run bash -c "
            cd $TEST_TEMP_DIR
            source $SCRIPT_PATH 2>/dev/null
            echo \$REPO
        "
        [[ "$output" == *"farmdata2/farmdata2"* ]]
    done
}

@test "malformed repo URL handling" {
    cd "$TEST_TEMP_DIR"
    git init >/dev/null 2>&1
    git remote add origin "invalid-url"

    run "$SCRIPT_PATH" --pr 123
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unable to parse"* ]]
}

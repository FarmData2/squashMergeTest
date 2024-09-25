#!/bin/bash

# Fake commit details
TYPE="feat"
SCOPE="docs"
TITLE="Add new feature X"
BODY="This is a detailed description of the new feature X.
It spans multiple lines to simulate a real PR description."
BREAKING_CHANGES="BREAKING CHANGE: This change breaks the existing API for feature Y."
CO_AUTHORS="Co-authored-by: Ty Chermsirivatana <chermsit@dickinson.edu>
Co-authored-by: Grant Braught <braught@dickinson.edu>"


generate_fake_commit() {
    local type=$1
    local scope=$2
    local title=$3
    local body=$4
    local breaking_changes=$5
    local co_authors=$6

    echo "${type}(${scope}): ${title}

${body}

${breaking_changes}

${co_authors}"
}

FAKE_COMMIT=$(generate_fake_commit "$TYPE" "$SCOPE" "$TITLE" "$BODY" "$BREAKING_CHANGES" "$CO_AUTHORS")

echo "Fake Commit Message:"
echo "--------------------"
echo "$FAKE_COMMIT"
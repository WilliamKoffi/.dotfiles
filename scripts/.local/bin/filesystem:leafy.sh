#!/bin/bash

# Check if a directory was provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory>"
    echo "Description: This script finds and prints all directories within"
    echo "the specified directory that do not contain any subdirectories."
    echo "If no argument is provided, it displays this usage information."
    exit 1
fi

# Find directories without subdirectories
find "$1" -type d | while read -r dir; do
    # Check if the current directory has any subdirectories
    if [ -z "$(find "$dir" -mindepth 1 -type d)" ]; then
        # If no subdirectories are found, print the directory
        echo "$dir"
    fi
done


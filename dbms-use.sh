#!/bin/bash

source ./common.sh

# Function to handle USE SQL queries for database selection
function handleUse(){
    local useQuery="$1"      # The complete USE query string
    
    # Regex to parse USE query syntax
    local sql_regex='^[[:space:]]*(USE|use)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*;[[:space:]]*$'
    clear 
    echo $useQuery
    
    # Check if query matches the expected USE syntax
    if [[ "$useQuery" =~ $sql_regex ]] 
    then
        # Extract database name from regex match group
        local databaseName="${BASH_REMATCH[2]}" 
        
        # Check if base directory exists
        if [[ -d $baseDir ]]
        then 
            # Check if specified database exists
            if [[ -d $baseDir/$databaseName ]]
            then 
                # Set current database context
                currentDB="$databaseName"
                # Export variable to make it available to other scripts/functions
                export currentDB
                # Navigate to table operations menu for the selected database
                printTableMenu 

            else
                # Database doesn't exist - inform user
                echo "Database doesn't exist. Enter a valid database name."
                return
            fi 
        else
            # Base directory doesn't exist - critical system error
            echo "Error: Directory '$baseDir' does not exist."
            # Attempt to recover by creating base directory
            initialize_application
            echo "Created base directory '$baseDir'."
            echo "Please create a database first."
            return
        fi 
    else 
        # Query doesn't match expected USE syntax
        echo "Invalid USE query syntax."
        echo "Accepted forms:"
        echo "  USE databaseName;"
        echo "Only full lowercase or uppercase accepted."
    fi 
}
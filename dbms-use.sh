#!/bin/bash
source ./common.sh

function handleUse(){
    local useQuery="$1"
    local sql_regex='^[[:space:]]*(USE|use)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*;[[:space:]]*$'
    clear 
    echo $useQuery
    
    if [[ "$useQuery" =~ $sql_regex ]] 
    then
        local databaseName="${BASH_REMATCH[2]}" 
        if [[ -d $baseDir ]]
        then 
            if [[ -d $baseDir/$databaseName ]]
            then 
                currentDB="$databaseName"
                export currentDB
                printTableMenu 

            else
                echo "Database doesn't exist. Enter a valid database name."
                return
            fi 
        else
            echo "Error: Directory '$baseDir' does not exist."
            initialize_application
            echo "Created base directory '$baseDir'."
            echo "Please create a database first."
            return
        fi 
    else 
        echo "Invalid USE query syntax."
        echo "Accepted forms:"
        echo "  USE databaseName;"
        echo "Only full lowercase or uppercase accepted."
    fi 
}

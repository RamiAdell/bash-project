#!/bin/bash

shopt -s extglob

source ./dbms-update.sh
source ./dbms-insert.sh
source ./dbms-select.sh
source ./dbms-delete.sh

# current selected database
currentDB="seif"
# current base directory for databases
baseDir="./Databases"


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
                echo "Using database '$currentDB'."            
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
initialize_application() {
    if [ ! -d "$baseDir" ]; then
        mkdir -p "$baseDir"
    fi
}

function main(){
    set -f 
    echo "Welcome to oursql Engine!"
    while true 
    do 
        read -r -p ">" query

        query=$(echo "$query" | sed 's/^[ \t]*//;s/[ \t]*$//')
        if [[ "$query" =~ ^[[:space:]]*(exit|quit)[[:space:]]*$ ]]; then
            echo "Exiting..."
            break
        fi
        cmd=$(echo "$query" | awk '{print toupper($1)}')
        case "$cmd" in
            SELECT)
                if [[ -z "$currentDB" ]]; then
                    echo "No database selected. Use 'USE databaseName;' to select a database."
                    continue
                fi
                handleSelect "$query"
                ;;
            INSERT)
                if [[ -z "$currentDB" ]]; then
                    echo "No database selected. Use 'USE databaseName;' to select a database."
                    continue
                fi
                handleInsert "$query"
                ;;
            DELETE)
                if [[ -z "$currentDB" ]]; then
                    echo "No database selected. Use 'USE databaseName;' to select a database."
                    continue
                fi
                handleDelete "$query"
                ;;
            UPDATE)
                if [[ -z "$currentDB" ]]; then
                    echo "No database selected. Use 'USE databaseName;' to select a database."
                    continue
                fi
                handleUpdate "$query"
                ;;
            USE)
                handleUse "$query"
                ;;
            *)
                clear
                echo "Invalid or unsupported SQL command."
                echo "------AVAILABLE SQL COMMANDS------"
                echo "------SELECT------"
                echo "------INSERT------"
                echo "------UPDATE------"
                echo "------DELETE------"
                echo "------DROP------"
                ;;
        esac
    done
    set +f 
}
initialize_application
main
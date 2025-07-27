#!/bin/bash

shopt -s extglob

source ./dbms-update.sh
source ./dbms-insert.sh
source ./dbms-select.sh
source ./dbms-delete.sh

# current selected database
currentDB=""
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

function createDB(){

    while true; do
    clear

    read -p "Enter database name or ($) to go back: " dbName
    if [[ "$dbName" == "\$" ]]
    then 
        clear
        return 
    fi    
    if [ -d "$baseDir/$dbName" ]; then
        echo "Database '$dbName' already exists. Please choose another name."
        continue
    fi

    if [ -z "$dbName" ]; then
        echo "Database name cannot be empty. Please try again."
        continue
    fi

    if [[ ! "$dbName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Database Must start with a letter or underscore and contain only letters, digits, or underscores."
        continue
    fi


    mkdir -p "$baseDir/$dbName"
    clear
    echo "Database name '$dbName' is Created."
    break
    done

}

function listDB(){
    clear
    dbNames=()
    for db in "$baseDir"/*; do
        [[ -d "$db" ]] && dbNames+=("$(basename "$db")")
    done

    if [[ ${#dbNames[@]} -eq 0 ]]; then
        echo "No available databases"
    else
        echo ""
        echo Available Databases: 
        echo
        echo "${dbNames[*]}" | sed 's/ /, /g'
    fi
}

function connectDB(){

    clear
    while true; do

    dbList=()
    dbCount=0

    if [ -d "$baseDir" ]; then
        echo "Available Databases:"
        for db in "$baseDir"/*; do
            if [ -d "$db" ]; then
                dbCount=$((dbCount + 1))
                dbName=$(basename "$db")
                echo "$dbCount. $dbName"
                dbList+=("$dbName")
            fi
        done

        if [ ${#dbList[@]} -eq 0 ]; then
            echo "No databases found"
            break
        fi
        echo ""
        echo "To go back to main menu, enter 0" 
        read -p "Enter database number to select or 'new' to create new database: " choice
        if [[ "$choice" == "0" ]]; then
            clear
            return
        fi
        if [[ "$choice" = "new" ]]; then
        createDB
        continue
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#dbList[@]}" ]; then
            index=$((choice-1))
            selectedDB="${dbList[$index]}"
            clear
            printTableMenu
            return
            
        else
            echo "Invalid selection."
            
        fi

    else
        echo "Error: Directory '$baseDir' does not exist."
        exit 1
    fi

    done
}

function dropDB(){
    PS3="Enter the DB number to drop: "
    while true
    do 
        dbList=("$baseDir"/*)
        dbNames=()
        for db in "${dbList[@]}"
        do 
            if [[ -d $db ]] 
            then  
                dbName=`basename $db`
                dbNames+=("$dbName")
            fi 
        done
        if [[ ${#dbNames[@]} -eq 0 ]]; then
            echo "No databases found in $baseDir"
            echo "Exiting...."
          return
        fi

        dbNames+=("--Back to Main Menu--")
       
        select dbName in "${dbNames[@]}"
        do
            if [[ "$REPLY" -eq "${#dbNames[@]}" ]]
            then
                echo Exiting....
                PS3="Enter a valid number to proceed: "
                return 
            fi
            if [[ -n "$dbName" ]]; then
                read -p "Are you sure you want to delete '$dbName'? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]
                then
                    rm -rf "$baseDir/$dbName"
                    echo "Database '$dbName' deleted successfully."
                else
                    echo "Deletion cancelled."
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
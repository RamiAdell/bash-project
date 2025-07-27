#!/bin/bash
source ./dbms-update.sh
source ./dbms-insert.sh
source ./dbms-select.sh
source ./dbms-delete.sh
source ./dbms-use.sh
source ./common.sh

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
        echo "${dbNames[*]}" | sed 's/ / , /g'
    fi
}
function isValidQuery() {
    local input="$1"
    if [[ "$input" =~ ^[[:space:]]*(SELECT|select|INSERT|insert|UPDATE|update|DELETE|delete|USE|use)[[:space:]] ]] ; then
        return 0
    fi
    return 1
}
function handleQuery() {
    set -f 
    local query="$1"
    local cmd=$(echo "$query" | awk '{print toupper($1)}')
    
    case "$cmd" in
        SELECT)
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
            handleSelect "$query"
            ;;
        INSERT)
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
            handleInsert "$query"
            ;;
        DELETE)
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
            handleDelete "$query"
            ;;
        UPDATE)
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
            handleUpdate "$query"
            ;;
        USE)
            handleUse "$query"
            ;;
        *)
            echo "Invalid or unsupported SQL command."
            echo "------AVAILABLE SQL COMMANDS------"
            echo "USE, SELECT, INSERT, UPDATE, DELETE"
            ;;
    esac
    set +f 
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
                    dbList+=("$dbName")
                fi
            done
            if [ ${#dbList[@]} -eq 0 ]; then
                echo "No databases found"
                break
            fi
            
            # Create options array for select
            local selectOptions=("${dbList[@]}" "Create New Database" "Back to Main Menu")
    
            PS3="Enter choice number or SQL query: "
            
            select dbChoice in "${selectOptions[@]}"
            do
                # Check if input is a SQL query
                if isValidQuery "$REPLY"; then
                    handleQuery "$REPLY"
                    break
                fi
                
                # Handle numbered selections
                case $REPLY in
                    [1-9]|[1-9][0-9])
                        if [ "$REPLY" -le "${#dbList[@]}" ]; then
                            index=$((REPLY-1))
                            currentDB="${dbList[$index]}"
                            export currentDB
                            clear
                            echo "Connected to database: $currentDB"
                            printTableMenu
                            return
                        elif [ "$REPLY" -eq $((${#dbList[@]} + 1)) ]; then
                            # Create New Database
                            createDB
                            break
                        elif [ "$REPLY" -eq $((${#dbList[@]} + 2)) ]; then
                            # Back to Main Menu
                            clear
                            return
                        else
                            echo "Invalid selection. Please try again."
                            break
                        fi
                        ;;
                    *)
                        echo "Invalid input. Enter a number or SQL query ending with semicolon."
                        break
                        ;;
                esac
            done
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
                break
            else
                echo "Invalid choice. Try again."
            fi
        done

    done
}


function printTableMenu(){
    tableOptions=("Create Table" "Insert into Table" "Update Table" "Delete from Table" "Show Table Data" "List Tables" "Drop Table" "Back to Main Menu")
    while true; do
        
        echo ""
        echo "Selected Database: $currentDB"
        echo ""        
        
        PS3="Enter choice number or SQL query: "
        
        select tableChoice in "${tableOptions[@]}"
        do
            # Check if input is a SQL query
            if isValidQuery "$REPLY"; then
                handleQuery "$REPLY"
                break
            fi
            
            # Handle numbered selections
            case $REPLY in 
                1)
                    createTable 
                    break
                    ;;
                2)
                    insertInTable
                    break
                    ;;
                3)
                    updateInTable
                    break
                    ;;
                4)
                    deleteInTable
                    break
                    ;;
                5)
                    showTableData
                    break
                    ;;
                6)
                    listTables 
                    break
                    ;;
                7)
                    dropTable
                    break
                   ;;
                8)
                    clear
                    return
                    ;;
                *)
                    echo "Invalid input. Enter a number from 1 to 8 or a valid SQL query ending with semicolon."
                    break
                    ;;
            esac
        done   
    done
}
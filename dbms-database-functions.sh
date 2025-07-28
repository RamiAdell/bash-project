#!/bin/bash

source ./dbms-update.sh    # Contains UPDATE query handlers
source ./dbms-insert.sh    # Contains INSERT query handlers
source ./dbms-select.sh    # Contains SELECT query handlers
source ./dbms-delete.sh    # Contains DELETE query handlers
source ./dbms-use.sh       # Contains USE query handlers
source ./common.sh         # Contains common variables and utility functions

# Function to create a new database
function createDB(){

    while true; do
    clear

    # Get database name from user with option to go back
    read -p "Enter database name or ($) to go back: " dbName
    if [[ "$dbName" == "\$" ]]
    then 
        clear
        return 
    fi    
    
    # Check if database already exists
    if [ -d "$baseDir/$dbName" ]; then
        echo "Database '$dbName' already exists. Please choose another name."
        continue
    fi

    # Check if database name is empty
    if [ -z "$dbName" ]; then
        echo "Database name cannot be empty. Please try again."
        continue
    fi

    # Validate database name format (must start with letter/underscore, contain only alphanumeric/underscore)
    if [[ ! "$dbName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Database Must start with a letter or underscore and contain only letters, digits, or underscores."
        continue
    fi

    # Create database directory
    mkdir -p "$baseDir/$dbName"
    clear
    echo "Database name '$dbName' is Created."
    break
    done

}

# Function to list all existing databases
function listDB(){
    clear
    dbNames=()
    
    # Iterate through all directories in base directory
    for db in "$baseDir"/*; do
        # Only include directories (databases)
        [[ -d "$db" ]] && dbNames+=("$(basename "$db")")
    done

    # Display results
    if [[ ${#dbNames[@]} -eq 0 ]]; then
        echo "No available databases"
    else
        echo ""
        echo Available Databases: 
        echo
        # Convert array to comma-separated string for display
        echo "${dbNames[*]}" | sed 's/ / , /g'
    fi
}

# Function to validate if input string is a valid SQL query
function isValidQuery() {
    local input="$1"
    # Check if input starts with one of the supported SQL commands
    if [[ "$input" =~ ^[[:space:]]*(SELECT|select|INSERT|insert|UPDATE|update|DELETE|delete|USE|use)[[:space:]] ]]  
    then
        return 0
    fi
    return 1
}

# Function to handle and route SQL queries to appropriate handlers
function handleQuery() {
    set -f  # Disable filename expansion to prevent issues with SQL queries (* in select query)
    local query="$1"
    # Extract the first word (command) and convert to uppercase
    local cmd=$(echo "$query" | awk '{print toupper($1)}')
    
    # Route query to appropriate handler based on command
    case "$cmd" in
        SELECT)
            # Check if database is selected before allowing SELECT operations
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
            handleSelect "$query"
            ;;
        INSERT)
            # Check if database is selected before allowing INSERT operations
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
            handleInsert "$query"
            ;;
        DELETE)
            # Check if database is selected before allowing DELETE operations
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
            handleDelete "$query"
            ;;
        UPDATE)
            # Check if database is selected before allowing UPDATE operations
            if [[ -z "$currentDB" ]]; then
                echo "No database selected. Use 'USE databaseName;' to select a database."
                return
            fi
                if [[ "$query" =~ [Ww][Hh][Ee][Rr][Ee] ]]; then
             
                handleUpdateCondition "$query"
            else
               
                handleUpdate "$query"
            fi
    
            ;;
        USE)
            # USE command doesn't require existing database selection
            handleUse "$query"
            ;;
        *)
            # Handle unsupported commands
            echo "Invalid or unsupported SQL command."
            echo "------AVAILABLE SQL COMMANDS------"
            echo "USE, SELECT, INSERT, UPDATE, DELETE"
            ;;
    esac
    set +f  # Re-enable filename expansion
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
                            clear
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
# Function to drop (delete) an existing database
function dropDB(){
    clear
    PS3="Enter the DB number to drop: "
    while true
    do 
        # Get list of all directories in base directory
        dbList=("$baseDir"/*)
        dbNames=()
        
        # Extract database names from directory paths
        for db in "${dbList[@]}"
        do 
            if [[ -d $db ]] 
            then  
                dbName=`basename $db`
                dbNames+=("$dbName")
            fi 
        done
        
        # Check if any databases exist
        if [[ ${#dbNames[@]} -eq 0 ]]; then
            echo "No databases found in $baseDir"
            echo "Exiting...."
          return
        fi

        # Add back navigation option
        dbNames+=("--Back to Main Menu--")
       
        # Present database selection menu
        echo "Available Databases:"
        select dbName in "${dbNames[@]}"
        do
            # Check if user selected back option
            if [[ "$REPLY" -eq "${#dbNames[@]}" ]]
            then
                clear
                return 
            fi
            
            # Process valid database selection
            if [[ -n "$dbName" ]]; then
                # Ask for confirmation before deletion
                read -p "Are you sure you want to delete '$dbName'? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]
                then
                    clear
                    echo "Deleting database '$dbName'..."
                    # Remove database directory and all contents
                    rm -rf "$baseDir/$dbName"
                    echo "Database '$dbName' deleted successfully."
                else
                    clear
                    echo "Deletion cancelled."
                fi
                break
            else
                echo "Invalid choice. Try again."
            fi
        done

    done
}

# Function to display table operations menu after database selection
function printTableMenu(){
    # Define available table operations
    tableOptions=("Create Table" "Insert into Table" "Update Table" "Delete from Table" "Show Table Data" "List Tables" "Drop Table" "Back to Main Menu")
    inTableMenu=1
    export inTableMenu
    while true; do
        
        echo ""
        echo "Selected Database: $currentDB"
        echo ""        
        
        PS3="Enter choice number or SQL query: "
        
        # Present table operations menu
        select tableChoice in "${tableOptions[@]}"
        do
            # Check if user entered a SQL query instead of number
            if isValidQuery "$REPLY"; then
                handleQuery "$REPLY"
                break
            fi
            
            # Handle numbered menu selections
            case $REPLY in 
                1)
                    createTable    # Create new table
                    break
                    ;;
                2)
                    insertInTable  # Insert data into table
                    break
                    ;;
                3)
                    updateInTable  # Update existing table data
                    break
                    ;;
                4)
                    deleteInTable  # Delete data from table
                    break
                    ;;
                5)
                    showTableData  # Display table contents
                    break
                    ;;
                6)
                    listTables     # List all tables in current database
                    break
                    ;;
                7)
                    dropTable      # Delete entire table
                    break
                   ;;
                8)
                    clear
                    inTableMenu=0
                    export inTableMenu
                    return         # Go back to main menu
                    ;;
                *)
                    # Invalid selection
                    echo "Invalid input. Enter a number from 1 to 8 or a valid SQL query ending with semicolon."
                    break
                    ;;
            esac
        done   
    done
    
}
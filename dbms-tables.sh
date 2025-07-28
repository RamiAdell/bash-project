#!/bin/bash

shopt -s extglob

source ./common.sh

# Main function to create a new table in the current database
function createTable(){
    clear
    # Define available data types for table columns
    dataTypes=("int" "float" "character" "string" "email" )
    # Loop to get valid table name from user
    while true
    do 
        echo ""
        read -p "Enter the table name: (write $ to quit) " tableName
        echo ""

        # Check if table already exists
        if [[ -f "$baseDir/$currentDB/$tableName" ]]
        then 
            echo "Table $tableName already exists. Please choose another name."
            continue
        # Check if table name is empty
        elif [[ -z "$tableName" ]]
        then 
            echo "Table name cannot be empty. Please try again."
            continue
        # Check if user wants to quit
        elif [[ "$tableName" == "\$" ]]
        then 
            clear
            return     
        # Validate table name format (must start with letter/underscore, contain only alphanumeric/underscore)
        elif [[ ! "$tableName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
        then     
            echo "Table name must start with a letter or underscore and contain only letters, digits, or underscores."
            continue
        else 
            break
        fi 
    done
    
    # Flag to track if primary key has been assigned (only one PK allowed per table)
    pkFlag=1
    
    # Loop to get valid number of columns from user
    while true 
    do 
        read -p "Enter the number of columns(Maximum 5 digits) (or $ to go back): " columns
        if [[ "$columns" == "\$" ]]
        then 
            clear
            return 
        fi   
        # Validate column count (must be 1-5 digit number)
        if [[ $columns =~ ^[0-9]{1,5}$ ]]
        then 
            break
        else
            echo Invalid input. Please enter a valid 5 digits number.
        fi
    done
    
    # Create temporary file to store table metadata during creation
    tempMetaFile=$(mktemp)
    
    # Loop through each column to get its details
    for (( i=0; i<columns ; i++ ))
    do  
        clear 
        # Read column name and validate it
        readColumnName $i "$tempMetaFile"
        if [[ $? -ne 0 ]]; then
            return
        fi
        # Read column data type
        readDataTypes
        if [[ $? -ne 0 ]]; then
            return
        fi
        # Ask for primary key designation (only for first eligible column)
        if [[ $pkFlag -eq 1 ]]
        then 
            read -p "Do you want to make this column as a primary key? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]
            then
                pkColumn="pk"
                pkFlag=0  # Disable PK flag after assigning one
            fi
        else
            pkColumn=""
        fi 
        # Write column metadata to temporary file (format: columnName:dataType:pkFlag)
        echo "$columnName:$colDataType:$pkColumn" >> "$tempMetaFile"
    done
    
    # Copy temporary metadata file to permanent location with hidden filename
    cp "$tempMetaFile" "$baseDir/$currentDB/.${tableName}-metadata"
    # Create empty table file
    touch "$baseDir/$currentDB/$tableName"
    # Clean up temporary file
    rm "$tempMetaFile"
    clear
    echo "Table '$tableName' created successfully in database '$currentDB'."

}

# Function to read and validate column data type selection
function readDataTypes(){
    while true
    do 
        echo "Select $columnName data type($ to quit): "
        select dataType in "${dataTypes[@]}"
        do 
            # Check if user wants to quit
            if [[ "$REPLY" == "\$" ]]; then
                clear
                return 1  
            fi
            # Validate selection (1-5 for available data types)
            case $REPLY in 
            1|2|3|4|5 ) 
                colDataType="${dataTypes[$((REPLY-1))]}"
                break
                ;;
            *)
                echo "Invalid choice."
                continue
            esac
        done
        break 
    done 
}

# Function to read and validate column name, ensuring no duplicates
function readColumnName(){
    colIdx=$1              # Column index for display
    tempMetaFile=$2        # Temporary metadata file to check for duplicates
    while true
    do 
        read -p "Enter the column $((colIdx+1)) name ($ to quit) : " columnName
        echo ""
        # Check if user wants to quit
        if [[ "$columnName" == "\$" ]]
        then 
            clear
            return 1
        fi   
        # Check if column name already exists in metadata file
        if cut -d ':' -f1 "$tempMetaFile" | grep -xq "$columnName" 
        then
            echo "Column $columnName already exists. Please choose another name."
            continue
        # Check if column name is empty
        elif [[ -z "$columnName" ]]
        then 
            echo "Column name cannot be empty. Please try again."
            continue  
        # Validate column name format
        elif [[ ! "$columnName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
        then     
            echo "Column name must start with a letter or underscore and contain only letters, digits, or underscores."
            continue
        else 
            break
        fi 
    done
}

# Function to list all tables in the current database (simple display)
function listTables(){
    clear
    tableNames=()
    # Iterate through all files in current database directory
    for table in "$baseDir/$currentDB"/*; do
        # Only include regular files (not metadata files which start with .)
        [[ -f "$table" ]] && tableNames+=("$(basename "$table")")
    done

    # Display results
    if [[ ${#tableNames[@]} -eq 0 ]]; then
        echo "No available tables"
    else
        echo ""
        echo Available Tables: 
        echo "${tableNames[*]}" | sed 's/ / , /g'  # Convert array to comma-separated string
    fi
}

# Function to prepare table list for selection menus (adds back option)
function listTablesPreProcess(){
    # Get list of all files in current database directory
    tableList=("$baseDir/$currentDB"/*)
    # Array to hold actual table names (excluding metadata files)
    tableNames=()
    for table in "${tableList[@]}"
    do 
        # Only include regular files (tables, not directories or metadata)
        if [[ -f $table ]] 
        then  
            tableName=`basename $table`
            tableNames+=("$tableName")
        fi 
    done
    # Check if no tables exist in current database
    if [[ ${#tableNames[@]} -eq 0 ]]; then
        echo "No tables found in database $currentDB"
        echo "Exiting...."
        return
    fi

    # Add back navigation option to the list
    tableNames+=("--Back to table operations Menu--")
}

# Function to drop (delete) a table from the current database
function dropTable(){
    clear
    echo "DROP TABLE"  
    echo ""
    PS3="Enter the Table number to drop: "
    while true
    do 
        # Get list of available tables
        listTablesPreProcess
        select tableName in "${tableNames[@]}"
        do
            # Check if user selected the back option
            if [[ "$REPLY" -eq "${#tableNames[@]}" ]]
            then
                echo Exiting....
                PS3="Enter a valid number to proceed: "
                return 
            fi
            # Process valid table selection
            if [[ -n "$tableName" ]]; then
                # Ask for confirmation before deletion
                read -p "Are you sure you want to delete '$tableName'? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]
                then
                    # Remove both table file and its metadata file
                    rm -rf "$baseDir/$currentDB/$tableName" "$baseDir/$currentDB/.${tableName}-metadata"
                    echo "Tabel '$tableName' deleted successfully."
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

# Main function to handle different types of delete operations
function deleteInTable(){
    
    deleteAllFlag=1    # Flag for deleting all matching records
    deleteoneFlag=0    # Flag for deleting single record
    while true
    do  
        clear
        echo "DELETE DATA"
        echo ""
        # Present delete operation options to user
        select choice in "Delete all table?" "Delete one record from table?" "Delete all records from table WHERE condition?" "--Back to table operations Menu--"
        do 
            case $REPLY in 
            1)
                deleteAllTable    # Delete entire table contents
                return 
                ;;
            2)
                deleteFromTable $deleteoneFlag    # Delete single record
                return
                ;;
            3)
                deleteFromTable $deleteAllFlag    # Delete all matching records
                return
                ;;
            4)
                return 
                ;;
            *)
                echo Invalid choice.
                ;;
            esac
        done 

    done 
}

# Function to delete all contents from a selected table
function deleteAllTable(){
    PS3="Enter the Table number to delete: "
    clear 
    while true
    do 
        # Get list of available tables
        listTablesPreProcess
        select tableName in "${tableNames[@]}"
        do
            # Check if user selected back option
            if [[ "$REPLY" -eq "${#tableNames[@]}" ]]
            then
                clear
                return 
            fi
            # Process valid table selection
            if [[ -n "$tableName" ]]; then
                # Check if table is already empty
                if [[ ! -s $tablePath || $(grep -cve '^\s*$' "$tablePath") -eq 0 ]]
                then 
                    clear
                    echo "Table is already empty."
                    return 
                fi
                # Ask for confirmation before deletion
                read -p "Are you sure you want to delete '$tableName'? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]
                then
                    clear 
                    # Clear table contents (empty the file)
                    echo "" > "$baseDir/$currentDB/$tableName"
                    echo "Tabel '$tableName' content deleted successfully."
                    return 
                else
                    echo "Deletion cancelled."
                fi
                break
            else
                echo "Invalid choice. Try again."
            fi
        done
        break
    done

}

# Function to delete specific records from a table based on WHERE condition
function deleteFromTable() {
    # Get list of available tables
    listTablesPreProcess
    PS3="Enter the Table number to delete from: "
    clear 
    deleteFlag=$1    # Flag to determine delete behavior (single vs all matching)
    echo "Available Tables:"
    select tableName in "${tableNames[@]}"; do
        if [[ "$REPLY" -eq "${#tableNames[@]}" ]]
        then
            clear
            return 
        fi
        # Validate table selection
        if [[ -z "$tableName" ]]; then
            echo "Invalid choice. Try again."
            continue
        fi

        # Set paths for table and its metadata
        tablePath="$baseDir/$currentDB/$tableName"
        metaPath="$baseDir/$currentDB/.$tableName-metadata"

        # Check if table and metadata files exist
        if [[ ! -f "$tablePath" || ! -s "$metaPath" ]]; then
            echo "Table or its metadata doesn't exist or is empty."
            return
        fi

        # Check if table has any data (-c to count the lines, -v to invert the matching pattern, -e with the provided 
        # pattern to get the count of non-empty lines)
        if [[ ! -s $tablePath || $(grep -cve '^\s*$' "$tablePath") -eq 0 ]]; then 
            clear
            echo "Table is already empty."
            return 
        fi 

        clear
        echo -e "\nAvailable columns:"
        # Extract column names from metadata file
        columns=($(cut -d ':' -f1 "$metaPath"))

        # Display available columns with numbers
        i=1
        for col in "${columns[@]}"; do 
            echo "Column $i: $col"
            ((i++))
        done

        # Loop until user enters valid column name for WHERE condition
        while true; do
            read -p "Enter the column name to use in WHERE condition: " colName
            # Find column index in metadata file
            colIndex=$(grep -n "^$colName:" "$metaPath" | cut -d: -f1)
            if [[ -n "$colIndex" ]]; then
                break  # valid column found
            else
                echo "Column '$colName' not found. Please try again."
            fi
        done

        # Get value to match for deletion
        read -p "Enter the value to match for deletion: " targetValue

        # Find all matching rows and their line numbers
        local targetEncoded=$(echo -n "$targetValue" | base64)
        matchingRows=$(awk -F: -v col="$colIndex" -v val="$targetEncoded" '$col == val {print NR ": " $0}' "$tablePath")
        matchingCount=$(echo "$matchingRows" | grep -c '^')
        
        deleteTempFile=$(mktemp)
        echo "$matchingRows" > "$deleteTempFile"
        

        # Check if any matching rows found
        if [[ -z "$matchingRows" ]]; then
            clear 
            echo "No matching rows found."
            return
        fi

        clear 
        echo -e "\nMatching rows:"
        printDecodedFileN "$deleteTempFile" 

        rm "$deleteTempFile"
        # Handle deletion based on flag
        if [[ $deleteFlag -eq 1 ]]; then
            # Delete all matching rows
            echo -e "\nDeleting all $matchingCount matching rows..."
            # Delete from bottom to top to preserve line numbers during deletion
            echo "$matchingRows" | cut -d: -f1 | sort -rn | while read -r lineNum; do
                sed -i "${lineNum}d" "$tablePath"
            done
            echo "All matching rows deleted."

        elif [[ $deleteFlag -eq 0 ]]; then 
            # Delete single specific row
            read -p "Enter the row number to delete (or 0 to cancel): " rowNum

            if [[ "$rowNum" == "0" ]]; then
                echo "Deletion cancelled."
                return
            fi

            # Validate row number
            totalLines=$(wc -l < "$tablePath")
            if (( rowNum > totalLines || rowNum < 1 )); then
                echo "Invalid row number."
                return
            fi

            # Delete the specified row
            sed -i "${rowNum}d" "$tablePath"
            clear 
            echo "Row $rowNum deleted successfully."
        fi 
        break 
    done
}
showTableData() {

    clear
    echo ""
    echo "SHOWING DATA"
    echo ""

    tableList=()
    tableCount=0

    if [ -d "$baseDir/$currentDB" ]; then
        echo "Available Tables:"
        for table in "$baseDir/$currentDB/"*; do
            if [ -f "$table" ]; then
                tableCount=$((tableCount + 1))
                tableName=$(basename "$table")
                echo "$tableCount. $tableName"
                tableList+=("$tableName")
            fi
        done
        echo ""
        echo "to go back to table operations menu, enter 0"

        if [ ${#tableList[@]} -eq 0 ]; then
            echo "No tables found"
            return
        fi

        while true; do
            echo ""
            read -p "Select table by number: " tableChoice
            if [[ "$tableChoice" -eq 0 ]]; then
                clear
                return
            fi
            if [[ "$tableChoice" =~ ^[0-9]+$ ]] && [ "$tableChoice" -ge 1 ] && [ "$tableChoice" -le "${#tableList[@]}" ]; then
                index=$((tableChoice-1))
                selectedTable="${tableList[$index]}"
                metaDataFile="$baseDir/$currentDB/.$selectedTable-metadata"
                dataFile="$baseDir/$currentDB/$selectedTable"
                break
            else
                echo "Invalid selection. Try again."
                break
            fi
        done

    else
        echo "Database not found"
        return
    fi

    if [ ! -f "$dataFile" ] || [ ! -f "$metaDataFile" ]
    then
    echo "file missing for '$selectedTable'."
    return
    fi
    clear
    echo ""
    echo "Rows in '$selectedTable':"
    echo "-----------------------------"

    # Read column names and types
    columnNames=()
    columnTypes=()
    while IFS=':' read -r colName colType _; do
        columnNames+=("$colName")
        columnTypes+=("$colType")
    done < "$metaDataFile"

    headerLine="${columnNames[0]}"
    for ((i=1; i<${#columnNames[@]}; i++)); do
        headerLine+=" | ${columnNames[i]}"
    done

    
    echo "$headerLine"
    echo "-----------------------------"

    # Print each row (decoded and formatted)
    while IFS=':' read -r -a row; do
        for ((i = 0; i < ${#row[@]}; i++)); do
            decoded=$(echo "${row[$i]}" | base64 --decode)
            case "${columnTypes[$i]}" in
                string|email)
                    value="\"$decoded\""
                    ;;
                *)
                    value="$decoded"
                    ;;
            esac

            if [[ $i -eq 0 ]]; then
                echo -n "$value"
            else
                echo -n " | $value"
            fi
        done
        echo ""
    done < "$dataFile"

    echo ""
}
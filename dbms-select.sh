#!/bin/bash

source ./common.sh

# Function to print specific columns from a table file based on column selection
function printSelectedColumns(){
    local filePath="$1"
    local metaFile="$2"
    shift 2      
    local columnArray=("$@") # Array of column names to display
    
    # Array to store column indexes corresponding to selected column names
    declare -a colIndexes=()
    
    # Find the index of each selected column in the metadata file
    for colName in "${columnArray[@]}"; do
        # Search for column name in metadata and extract line number (which is the column index)
        index=$(grep -n "^$colName:" "$metaFile" | cut -d: -f1)
        colIndexes+=("$index")
    done

    # Sort column indexes numerically to maintain proper column order in output
    IFS=$'\n' sortedColIndexes=($(sort -n <<<"${colIndexes[*]}"))
    unset IFS

    # Build AWK command dynamically to extract and display selected columns
    awkCmd='BEGIN {FS=":"; OFS=":"} 
    {
        # Only print if one of the selected fields is non-empty
        if ('
    
    # Add condition to check if any selected field has data (not empty)
    for i in "${!sortedColIndexes[@]}"; do
        idx=${sortedColIndexes[$i]}
        awkCmd+="\$$idx != \"\""  # Check if field is not empty
        if (( i < ${#sortedColIndexes[@]} - 1 )); then
            awkCmd+=" || "        # OR condition between fields
        fi
    done
    awkCmd+=') {'

    # Add print statements for each selected column
    for i in "${!sortedColIndexes[@]}"; do
        idx=${sortedColIndexes[$i]}
        awkCmd+="printf \"%s\", \"\$(echo \$$idx | base64 --decode)\";" # Print field value
        if (( i < ${#sortedColIndexes[@]} - 1 )); then
            awkCmd+=" printf OFS; "       # Add field separator between columns
        fi
    done

    # Complete the AWK command
    awkCmd+='print "" } }'

    # Execute the dynamically built AWK command on the table file
    awk "$awkCmd" "$filePath"
}

# Main function to handle SELECT SQL queries
function handleSelect() {
    local selectQuery="$1"    # The complete SELECT query string
     
    clear 
    echo $selectQuery
    echo ""
    
    # Complex regex to parse SELECT query components
    local sql_regex='^[[:space:]]*(SELECT|select)[[:space:]]+(\*|([a-zA-Z_][a-zA-Z0-9_]*([[:space:]]*,[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*)*))[[:space:]]+(FROM|from)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]+(WHERE|where)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+)))?[[:space:]]*;[[:space:]]*$'
    
    # Check if query matches the expected SELECT syntax
    if [[ "$selectQuery" =~ $sql_regex ]]; then
        
        # Extract components from regex match groups
        local columnTempPart="${BASH_REMATCH[2]}"     # Column specification (* or column list)
        local tableName="${BASH_REMATCH[6]}"          # Table name
        local whereKeyword="${BASH_REMATCH[8]}"       # WHERE keyword (if present)
        local whereColumn="${BASH_REMATCH[9]}"        # Column name in WHERE clause
        local whereValue="${BASH_REMATCH[10]}"        # Value in WHERE clause
        
        # Clean WHERE value by removing quotes
        whereValue="${whereValue//\"/}"   # Remove double quotes
        whereValue="${whereValue//\'/}"   # Remove single quotes

        # Set file paths for table data and metadata
        local tablePath="$baseDir/$currentDB/$tableName"
        local metaPath="$baseDir/$currentDB/.$tableName-metadata"
        
        # Check if table exists
        if [[ ! -f $tablePath ]]
        then 
            echo ""
            echo "Table $tableName doesnt exist"
            echo ""
            return 
        fi
        
        local isSelectAll=0    # true if SELECT * is used
        local hasWhere=0       # true if WHERE clause is present
        
        # Read available columns from metadata file
        if [[ -f $metaPath ]]
        then 
            availableColumns=($(cut -d ':' -f1 "$metaPath"))
        else
            echo "Metadata file for table $tableName does not exist."
            return
        fi

        # Set WHERE flag if WHERE keyword was found
        [[ -n "$whereKeyword" ]] && hasWhere=1

        # Determine if this is a SELECT * or specific columns query
        if [[ "$columnTempPart" == "*" ]]
        then 
            isSelectAll=1
        else
            # Parse comma-separated column list
            local cleanCols="${columnTempPart//[[:space:]]/}"  # Remove all whitespace
            local -a columnPart
            IFS=',' read -ra columnPart <<< "$cleanCols"      # Split by comma into array
        fi 
        
        # Handle SELECT * queries
        if [[ $isSelectAll -eq 1 ]]
        then 
            # SELECT * with WHERE clause
            if [[ $hasWhere -eq 1 ]]
            then 
                # Validate that WHERE column exists in table
                local found=0
                for item in "${availableColumns[@]}" 
                do
                    if [[ "$item" == "$whereColumn" ]] 
                    then
                        found=1
                        break
                    fi
                done

                if [[ $found -eq 1 ]] 
                then
                    # Find column index and filter rows matching WHERE condition
                    local colIndex=$(grep -n "^$whereColumn:" "$metaPath" | cut -d: -f1)
                    awk -F':' -v val="$whereValue" -v col="$colIndex" '$col == val {print $0}' "$tablePath"
                else
                    echo "Column $whereColumn not found in the table $tableName."
                    return 
                fi

            else 
                # SELECT * without WHERE clause - show all data
                if [[ ! -s $tablePath || $(grep -cve '^\s*$' "$tablePath") -eq 0 ]]
                then 
                    echo ""
                    echo "Table is empty."
                    echo ""
                else
                    # Read column data types from metadata into an array
                    mapfile -t colTypes < <(cut -d: -f2 "$metaPath")

                    # Read and process each line in the table
                    while IFS= read -r line; do
                        IFS=':' read -ra fields <<< "$line"
                        for i in "${!fields[@]}"; do
                            decoded=$(echo "${fields[$i]}" | base64 --decode)
                            case "${colTypes[$i]}" in
                                string|email)
                                    fields[$i]="\"$decoded\""
                                    ;;
                                *)
                                    fields[$i]="$decoded"
                                    ;;
                            esac
                        done
                        (IFS=:; echo "${fields[*]}")
                    done < "$tablePath"
                    echo ""

                fi 
            fi
        else
            # Handle SELECT specific columns queries
            if [[ $hasWhere -eq 1 ]]
            then
                # SELECT specific columns with WHERE clause
                # Validate that all requested columns exist
                if array1_in_array2 columnPart availableColumns;
                then 
                    # Create temporary file to store filtered results
                    selectTmpFile=$(mktemp)
                    # Find WHERE column index and filter matching rows
                    local colIndex=$(grep -n "^$whereColumn:" "$metaPath" | cut -d: -f1)
                    awk -F':' -v val="$whereValue" -v col="$colIndex" '$col == val {print $0}' "$tablePath" >> "$selectTmpFile"
                    
                    # Check if any rows matched the WHERE condition
                    if [[ ! -s $selectTmpFile  ]]
                    then
                        echo "There are no matches."
                        return
                    fi 
                    # Display selected columns from filtered results
                    printSelectedColumns "$selectTmpFile" "$metaPath" "${columnPart[@]}" 
                else 
                    echo There is an error with the provided columns name.
                fi 

            else
                # SELECT specific columns without WHERE clause
                # Validate that all requested columns exist
                if array1_in_array2 columnPart availableColumns;
                then 
                    echo ""
                    # Display selected columns from entire table
                    printSelectedColumns "$tablePath" "$metaPath" "${columnPart[@]}" 
                    echo ""
                else 
                    echo There is an error with the provided columns name.
                fi 
            fi 
        fi 

    else
        # Query doesn't match expected SELECT syntax
        echo "Invalid SELECT query syntax"
        echo "-------AVAILABLE FORMATS-------"
        echo "  SELECT * FROM table;"
        echo "  SELECT col1,col2... FROM table;"
        echo "  SELECT * FROM table WHERE col=val;"
        echo "  SELECT col1 FROM table WHERE col2=val;"
        echo "Only full lowercase or uppercase accepted."
        return 
    fi
}
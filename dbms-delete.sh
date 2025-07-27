#!/bin/bash

source ./common.sh

# Main function to handle DELETE SQL queries
function handleDelete() {
    local deleteQuery="$1"    # The complete DELETE query string
    clear 
    echo $deleteQuery

    # Complex regex to parse DELETE query components
    local sql_regex='^[[:space:]]*(DELETE|delete)[[:space:]]+(FROM|from)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]+(WHERE|where)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+)))?[[:space:]]*;[[:space:]]*$'
    
    # Check if query matches the expected DELETE syntax
    if [[ "$deleteQuery" =~ $sql_regex ]] 
    then
        # Parse query components using simple word splitting (alternative to regex groups)
        local parts=($deleteQuery)
        local table="${parts[2]}"           # Extract table name from third word
        local whereKeyword="${parts[3]}"    # Check if WHERE keyword exists
        
        # Clean table name by removing semicolon if no WHERE clause
        if [[ -z "$whereKeyword" ]]
        then 
            table="${table%;}"  # Remove trailing semicolon
        fi 
        
        # Extract WHERE condition (everything after WHERE keyword)
        local condition="${deleteQuery#*$whereKeyword }"
        condition="${condition%;}"  # Remove trailing semicolon

        # Set file paths for table data and metadata
        local tablePath="$baseDir/$currentDB/$table"
        local metaPath="$baseDir/$currentDB/.$table-metadata"
        
        # Validate that both table and metadata files exist
        if [[ ! -f "$tablePath" || ! -f "$metaPath" ]]; then
            echo "Table or metadata file not found."
            return
        fi

        # Handle DELETE without WHERE clause (delete all rows)
        if [[ -z "$whereKeyword" ]] 
        then
            clear
            # Check if table is already empty
            if [[ ! -s $tablePath || $(grep -cve '^\s*$' "$tablePath") -eq 0 ]]
            then 
                echo "Table is already empty."
            else 
                # Clear all table contents by emptying the file
                > "$tablePath"
                echo "All rows deleted from table '$table'."
            fi
        else
            # Handle DELETE with WHERE clause (conditional deletion)
            
            # Validate WHERE condition syntax (column=value format)
            if [[ ! "$condition" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.+)$ ]] 
            then
                echo "Invalid WHERE condition syntax. Expected: column=value"
                return
            fi

            # Extract column name and target value from WHERE condition
            local colName="${BASH_REMATCH[1]}"      # Column name in WHERE clause
            local targetValue="${BASH_REMATCH[2]}"  # Value to match in WHERE clause

            # Clean target value by removing quotes
            targetValue="${targetValue//\"/}"   # Remove double quotes
            targetValue="${targetValue//\'/}"   # Remove single quotes

            # Find the column index in metadata file
            local colIndex=$(grep -n "^$colName:" "$metaPath" | cut -d: -f1)
            if [[ -z "$colIndex" ]]; then
                echo "Column '$colName' not found in table '$table'."
                return
            fi

            # Find all rows that match the WHERE condition
            # AWK returns line numbers of matching rows
            local matchingRows=$(awk -F: -v col="$colIndex" -v val="$targetValue" '$col == val {print NR}' "$tablePath")
            
            # Check if any rows match the condition
            if [[ -z "$matchingRows" ]]; then
                echo "No rows match condition: $colName = $targetValue"
                return
            fi

            # Delete matching rows (process in reverse order to maintain line numbers)
            echo "$matchingRows" | sort -rn | while read -r lineNum; do
                sed -i "${lineNum}d" "$tablePath"  # Delete line at specified number
            done

            echo "Deleted matching rows from '$table' where $colName = $targetValue."
        fi
    else
        # Query doesn't match expected DELETE syntax
        echo "Invalid DELETE query syntax."
        echo "Accepted forms:"
        echo "  DELETE FROM table_name;"
        echo "  DELETE FROM table_name WHERE column=value;"
        echo "Only full lowercase or uppercase accepted."
        return
    fi
}
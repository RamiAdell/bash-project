
source ./common.sh

function handleInsert() {
    local insertQuery="$1"
    clear
    echo $insertQuery

    # Regex for INSERT INTO table (col1,col2,...) VALUES (val1,val2,...);
    local sql_regex='^[[:space:]]*(INSERT|insert)[[:space:]]+(INTO|into)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\([[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*([[:space:]]*,[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*)*)[[:space:]]*\)[[:space:]]+(VALUES|values)[[:space:]]*\([[:space:]]*([^)]+)[[:space:]]*\)[[:space:]]*;[[:space:]]*$'
    
    if [[ "$insertQuery" =~ $sql_regex ]]; then
        local tableName="${BASH_REMATCH[3]}"
        local columnPart="${BASH_REMATCH[4]}"
        local valuesPart="${BASH_REMATCH[7]}"
        
        local tablePath="$baseDir/$currentDB/$tableName"
        local metaPath="$baseDir/$currentDB/.$tableName-metadata"
        
        if [[ ! -f "$tablePath" || ! -f "$metaPath" ]]; then
            echo "Table '$tableName' doesn't exist"
            return
        fi
        
        # Parse columns
        local cleanCols="${columnPart//[[:space:]]/}"
        local -a insertColumns
        IFS=',' read -ra insertColumns <<< "$cleanCols"
        
        # Read metadata
        local -a availableColumns=()
        local -a columnTypes=()
        local -a primaryKeys=()
        
        while IFS=':' read -r colName colType pkFlag; do
            availableColumns+=("$colName")
            columnTypes+=("$colType")
            if [[ "$pkFlag" == "pk" ]]; then
                primaryKeys+=("$colName")
            fi
        done < "$metaPath"
        
        # Check if all insert columns exist
        if ! array1_in_array2 insertColumns availableColumns; then

            echo "One or more columns dont exist in table '$tableName'"
            return
        fi
        
        # Parse values - handle quoted strings properly
        local -a insertValues=()
        local currentValue=""
        local inQuotes=0
        local quoteChar=""
        
        # Remove spaces around values
        valuesPart=$(echo "$valuesPart" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        for (( i=0; i<${#valuesPart}; i++ )); do
            char="${valuesPart:$i:1}"
            
            if [[ $inQuotes -eq 0 ]]; then
                if [[ "$char" == "'" || "$char" == '"' ]]; then
                    inQuotes=1
                    quoteChar="$char"
                elif [[ "$char" == "," ]]; then
                    # End of current value
                    currentValue=$(echo "$currentValue" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    insertValues+=("$currentValue")
                    currentValue=""
                else
                    currentValue+="$char"
                fi
            else
                if [[ "$char" == "$quoteChar" ]]; then
                    inQuotes=0
                    quoteChar=""
                else
                    currentValue+="$char"
                fi
            fi
        done
        
        # Add the last value
        currentValue=$(echo "$currentValue" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        insertValues+=("$currentValue")
        
        # Check if number of values matches number of columns
        if [[ ${#insertColumns[@]} -ne ${#insertValues[@]} ]]; then
            echo "Number of values (${#insertValues[@]}) doesn't match number of columns (${#insertColumns[@]})"
            return
        fi
        
        # Validate data types and check for primary key duplicates
        for i in "${!insertColumns[@]}"; do
            local colName="${insertColumns[$i]}"
            local colValue="${insertValues[$i]}"
            
            # Find column index and type
            for j in "${!availableColumns[@]}"; do
                if [[ "${availableColumns[$j]}" == "$colName" ]]; then
                    local colType="${columnTypes[$j]}"
                    
                    # Validate data type
                    if ! validateDataType "$colValue" "$colType"; then
                        echo "Data type validation failed for column '$colName': expected $colType"
                        return
                    fi
                    
                    # Check if this is a primary key column
                    for pk in "${primaryKeys[@]}"; do
                        if [[ "$pk" == "$colName" ]]; then
                            if ! checkPrimaryKeyDuplicate "$tablePath" "$metaPath" "$colName" "$colValue"; then
                                return
                            fi
                            break
                        fi
                    done
                    break
                fi
            done
        done
        
        # Create the row data - initialize with empty values for all columns
        local -a rowData=()
        for col in "${availableColumns[@]}"; do
            rowData+=("")
        done
        
        # Fill in the provided values
        for i in "${!insertColumns[@]}"; do
            local colName="${insertColumns[$i]}"
            local colValue="${insertValues[$i]}"
            
            # Find the index of this column in the available columns
            for j in "${!availableColumns[@]}"; do
                if [[ "${availableColumns[$j]}" == "$colName" ]]; then
                    rowData[$j]="$colValue"
                    break
                fi
            done
        done
        
        # Write the row to the table file
        local rowString=""
        for i in "${!rowData[@]}"; do
            rowString+="${rowData[$i]}"
            if [[ $i -lt $((${#rowData[@]} - 1)) ]]; then
                rowString+=":"
            fi
        done
        
        echo "$rowString" >> "$tablePath"
        echo "Row inserted into table '$tableName'"
        
    else
        echo "Invalid INSERT query syntax"
        echo "-------AVAILABLE FORMAT-------"
        echo "  INSERT INTO table (col1,col2,...) VALUES (val1,val2,...);"
        echo "Only full lowercase or uppercase accepted."
        return
    fi
}
#!/bin/bash
source ./common.sh


function handleUpdate() {
    local updateQuery="$1"
    clear 
    echo $updateQuery

    # Regex for UPDATE table SET col=value (without WHERE);
    local sql_regex='^[[:space:]]*(UPDATE|update)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+(SET|set)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+))[[:space:]]*;[[:space:]]*$'
    
    if [[ "$updateQuery" =~ $sql_regex ]]; then
        local tableName="${BASH_REMATCH[2]}"
        local setColumn="${BASH_REMATCH[4]}"
        local setValue="${BASH_REMATCH[5]}"
        


        # Clean quotes from values
        setValue="${setValue//\"/}"
        setValue="${setValue//\'/}"
        
        local encodedSetValue
        encodedSetValue=$(encodeString "$setValue")
        
        local tablePath="$baseDir/$currentDB/$tableName"
        local metaPath="$baseDir/$currentDB/.$tableName-metadata"
        
        if [[ ! -f "$tablePath" || ! -f "$metaPath" ]]; then
            echo "Table '$tableName' doesnt exist"
            return
        fi
        
        if [[ ! -s "$tablePath" ]]; then
            echo "Table '$tableName' is empty"
            return
        fi
        
        # Read metadata
        local -a availableColumns=()
        local -a columnTypes=()
        local -a primaryKey=()
        
        while IFS=':' read -r colName colType pkFlag; do
            availableColumns+=("$colName")
            columnTypes+=("$colType")
            if [[ "$pkFlag" == "pk" ]]; then
                primaryKey+=("$colName")
            fi
        done < "$metaPath"
        
        # Check if SET column exists
        local setColFound=0
        local setColIndex=""
        local setColType=""
        for i in "${!availableColumns[@]}"; do
            if [[ "${availableColumns[$i]}" == "$setColumn" ]]; then
                setColFound=1
                setColIndex=$((i + 1))  # awk uses 1-based indexing
                setColType="${columnTypes[$i]}"
                break
            fi
        done
        
        if [[ $setColFound -eq 0 ]]; then
            echo "Column '$setColumn' not found in table '$tableName'"
            return
        fi
        
        # Validate data type
        if ! validateDataType "$setValue" "$setColType"; then
            echo "Data type validation failed for column '$setColumn': expected $setColType"
            return
        fi
        
        # Check if updating a primary key column
        local isPrimaryKey=0
        for pk in "${primaryKey[@]}"; do
            if [[ "$pk" == "$setColumn" ]]; then
                isPrimaryKey=1
                break
            fi
        done

        if [[ $isPrimaryKey -eq 1 ]]; then
            echo "Cannot update primary key column '$setColumn' for all rows without WHERE clause"
            return
        fi
        
        # Update all rows
        awk -F: -v OFS=':' -v setCol="$setColIndex" -v setVal="$encodedSetValue" '
            { $setCol = setVal; print }
        ' "$tablePath" > "${tablePath}.tmp" && mv "${tablePath}.tmp" "$tablePath"
        
        echo "Updated all rows in '$tableName', set $setColumn = $setValue"
        
    else

        echo "Invalid UPDATE query syntax"
        echo "-------AVAILABLE FORMAT-------"
        echo "  UPDATE table SET column=value;"
        echo "  UPDATE table SET column=value WHERE column=value;"
        echo "------------------------------"

        return
    fi
}

function handleUpdateCondition() {
    clear
    local updateQuery="$1"
    echo $updateQuery

    # Regex for UPDATE table SET col=value WHERE col=value;
    local sql_regex='^[[:space:]]*(UPDATE|update)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+(SET|set)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+))[[:space:]]+(WHERE|where)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+))[[:space:]]*;[[:space:]]*$'
    
    if [[ "$updateQuery" =~ $sql_regex ]]; then

        local tableName="${BASH_REMATCH[2]}"
        local setColumn="${BASH_REMATCH[4]}"
        local setValue="${BASH_REMATCH[5]}"
        local whereColumn="${BASH_REMATCH[10]}"
        local whereValue="${BASH_REMATCH[11]}"

        # Clean quotes from values
        setValue="${setValue//\"/}"
        setValue="${setValue//\'/}"
        whereValue="${whereValue//\"/}"
        whereValue="${whereValue//\'/}"
        


        local encodedSetValue
        encodedSetValue=$(encodeString "$setValue")
        local encodedWhereValue
        encodedWhereValue=$(encodeString "$whereValue")

        local tablePath="$baseDir/$currentDB/$tableName"
        local metaPath="$baseDir/$currentDB/.$tableName-metadata"
        
        if [[ ! -f "$tablePath" || ! -f "$metaPath" ]]; then
            echo "Table '$tableName' doesnt exist"
            return
        fi
        
        local -a availableColumns=()
        local -a columnTypes=()
        local -a primaryKey=()
        
        while IFS=':' read -r colName colType pkFlag; do
            availableColumns+=("$colName")
            columnTypes+=("$colType")
            if [[ "$pkFlag" == "pk" ]]; then
            primaryKey+=("$colName")
            fi
        done < "$metaPath"
        
        # check if SET column exists
        local setColFound=0
        local setColIndex=""
        local setColType=""
        for i in "${!availableColumns[@]}"; do
        if [[ "${availableColumns[$i]}" == "$setColumn" ]]; then
            setColFound=1
            setColIndex=$((i + 1))
            setColType="${columnTypes[$i]}"
            break
        fi
        done
        
        if [[ $setColFound -eq 0 ]]; then
            echo "Column '$setColumn' not found in table '$tableName'"
            return
        fi
        
        local whereColFound=0
        local whereColIndex=""
        for i in "${!availableColumns[@]}"; do
        if [[ "${availableColumns[$i]}" == "$whereColumn" ]]; then
            whereColFound=1
            whereColIndex=$((i + 1))
            break
        fi
        done
        
        if [[ $whereColFound -eq 0 ]]; then
            echo "Column '$whereColumn' not found in table '$tableName'"
            return
        fi
        
        if ! validateDataType "$setValue" "$setColType"; then
            echo "Data type validation failed for column '$setColumn': expected $setColType"
            return
        fi
        
        local matchingRows=$(awk -F: -v col="$whereColIndex" -v val="$encodedWhereValue" '$col == val {print NR}' "$tablePath")

        if [[ -z "$matchingRows" ]]; then
            echo "No rows match condition: $whereColumn = $whereValue"
            return
        fi
        
        local isPrimaryKey=0
        for pk in "${primaryKey[@]}"; do
            if [[ "$pk" == "$setColumn" ]]; then
                isPrimaryKey=1
                break
            fi
        done
        
        if [[ $isPrimaryKey -eq 1 ]]; then
            # For each matching row, check if the new PK value would create a duplicate
            echo "$matchingRows" | while read -r rowNum; do
                if ! checkPrimaryKeyDuplicate "$tablePath" "$metaPath" "$setColumn" "$setValue" "$rowNum"; then
                    exit 1
                fi
            done
            
            # Check if the while loop failed
            if [[ $? -eq 1 ]]; then
                return
            fi
        fi

        awk -F: -v OFS=':' -v setCol="$setColIndex" -v setVal="$encodedSetValue" -v whereCol="$whereColIndex" -v whereVal="$encodedWhereValue" '
            $whereCol == whereVal { $setCol = setVal }
            { print }
        ' "$tablePath" > "${tablePath}.tmp" 
        
        mv "${tablePath}.tmp" "$tablePath"
        echo "Updated rows in '$tableName' where $whereColumn = $whereValue, set $setColumn = $setValue"
        
    else
        echo "Invalid UPDATE query syntax"
        echo "-------AVAILABLE FORMAT-------"
        echo "  UPDATE table SET column=value;"
        echo "  UPDATE table SET column=value WHERE column=value;"
        echo "------------------------------"
        
        return
    fi
}
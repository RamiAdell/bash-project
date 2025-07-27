function handleDelete() {
    local deleteQuery="$1"
    clear 
    echo $deleteQuery

    local sql_regex='^[[:space:]]*(DELETE|delete)[[:space:]]+(FROM|from)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]+(WHERE|where)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+)))?[[:space:]]*;[[:space:]]*$'
    
    if [[ "$deleteQuery" =~ $sql_regex ]] 
    then
        local parts=($deleteQuery)
        local table="${parts[2]}"
        local whereKeyword="${parts[3]}"
        if [[ -z "$whereKeyword" ]]
        then 
            table="${table%;}"
        fi 
        local condition="${deleteQuery#*$whereKeyword }"
        condition="${condition%;}"

        local tablePath="$baseDir/$currentDB/$table"
        local metaPath="$baseDir/$currentDB/.$table-metadata"
        if [[ ! -f "$tablePath" || ! -f "$metaPath" ]]; then
            echo "Table or metadata file not found."
            return
        fi

        if [[ -z "$whereKeyword" ]] 
        then
            clear
            if [[ ! -s $tablePath ]]
            then 
                echo "Table is already empty."
            else 
                > "$tablePath"
                echo "All rows deleted from table '$table'."
            fi
        else
            if [[ ! "$condition" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.+)$ ]] 
            then
                echo "Invalid WHERE condition syntax. Expected: column=value"
                return
            fi

            local colName="${BASH_REMATCH[1]}"
            local targetValue="${BASH_REMATCH[2]}"

            targetValue="${targetValue//\"/}"
            targetValue="${targetValue//\'/}"

            local colIndex=$(grep -n "^$colName:" "$metaPath" | cut -d: -f1)
            if [[ -z "$colIndex" ]]; then
                echo "Column '$colName' not found in table '$table'."
                return
            fi

            local matchingRows=$(awk -F: -v col="$colIndex" -v val="$targetValue" '$col == val {print NR}' "$tablePath")
            if [[ -z "$matchingRows" ]]; then
                echo "No rows match condition: $colName = $targetValue"
                return
            fi

            echo "$matchingRows" | sort -rn | while read -r lineNum; do
                sed -i "${lineNum}d" "$tablePath"
            done

            echo "Deleted matching rows from '$table' where $colName = $targetValue."
        fi
    else
        echo "Invalid DELETE query syntax."
        echo "Accepted forms:"
        echo "  DELETE FROM table_name;"
        echo "  DELETE FROM table_name WHERE column=value;"
        echo "Only full lowercase or uppercase accepted."
        return
    fi
}
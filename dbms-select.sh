
source ./common.sh



function printSelectedColumns(){
    local filePath="$1"
    local metaFile="$2"
    shift 2  
    local columnArray=("$@")  
    
    declare -a colIndexes=()
    for colName in "${columnArray[@]}"; do
        index=$(grep -n "^$colName:" "$metaFile" | cut -d: -f1)
        colIndexes+=("$index")
    done

    IFS=$'\n' sortedColIndexes=($(sort -n <<<"${colIndexes[*]}"))
    unset IFS

    awkCmd='BEGIN {FS=":"; OFS=":"} 
    {
        # Only print if one of the selected fields is non-empty
        if ('
    for i in "${!sortedColIndexes[@]}"; do
        idx=${sortedColIndexes[$i]}
        awkCmd+="\$$idx != \"\""
        if (( i < ${#sortedColIndexes[@]} - 1 )); then
            awkCmd+=" || "
        fi
    done
    awkCmd+=') {'

    for i in "${!sortedColIndexes[@]}"; do
        idx=${sortedColIndexes[$i]}
        awkCmd+="printf \"%s\", \$$idx;"
        if (( i < ${#sortedColIndexes[@]} - 1 )); then
            awkCmd+=" printf OFS; "
        fi
    done

    awkCmd+='print "" } }'

    awk "$awkCmd" "$filePath"
}

function handleSelect() {
    local selectQuery="$1"
    clear 

    echo $selectQuery
    echo ""
    local sql_regex='^[[:space:]]*(SELECT|select)[[:space:]]+(\*|([a-zA-Z_][a-zA-Z0-9_]*([[:space:]]*,[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*)*))[[:space:]]+(FROM|from)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]+(WHERE|where)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+)))?[[:space:]]*;[[:space:]]*$'    
    if [[ "$selectQuery" =~ $sql_regex ]]; then
        
        local columnTempPart="${BASH_REMATCH[2]}"     
        local tableName="${BASH_REMATCH[6]}"      
        local whereKeyword="${BASH_REMATCH[8]}"   
        local whereColumn="${BASH_REMATCH[9]}"   
        local whereValue="${BASH_REMATCH[10]}"    
        whereValue="${whereValue//\"/}"
        whereValue="${whereValue//\'/}"

        local tablePath="$baseDir/$currentDB/$tableName"
        local metaPath="$baseDir/$currentDB/.$tableName-metadata"
        if [[ ! -f $tablePath ]]
        then 
            echo ""
            echo "Table $tableName doesnt exist"
            echo ""
            return 
        fi
        local isSelectAll=0
        local hasWhere=0
        if [[ -f $metaPath ]]
        then 
            availableColumns=($(cut -d ':' -f1 "$metaPath"))
        else
            echo "Metadata file for table $tableName does not exist."
            return
        fi

        [[ -n "$whereKeyword" ]] && hasWhere=1


        if [[ "$columnTempPart" == "*" ]]
        then 
            isSelectAll=1
        else
            local cleanCols="${columnTempPart//[[:space:]]/}"
            local -a columnPart
            IFS=',' read -ra columnPart <<< "$cleanCols"

        fi 
        
        if [[ $isSelectAll -eq 1 ]]
        then 
            if [[ $hasWhere -eq 1 ]]
            then 
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
                    local colIndex=$(grep -n "^$whereColumn:" "$metaPath" | cut -d: -f1)
                    awk -F':' -v val="$whereValue" -v col="$colIndex" '$col == val {print $0}' "$tablePath"
                else
                    echo "Column $whereColumn not found in the table $tableName."
                    return 
                fi

            else 
                if [[ ! -s $tablePath ]]
                then 
                    echo ""
                    echo "Table is empty."
                    echo ""
                else
                    cat $tablePath
                    echo ""
                fi 
            fi
        else
            if [[ $hasWhere -eq 1 ]]
            then
                if array1_in_array2 columnPart availableColumns;
                then 
                    selectTmpFile=$(mktemp)
                    local colIndex=$(grep -n "^$whereColumn:" "$metaPath" | cut -d: -f1)
                    awk -F':' -v val="$whereValue" -v col="$colIndex" '$col == val {print $0}' "$tablePath" >> "$selectTmpFile"
                    if [[ ! -s $selectTmpFile  ]]
                    then
                        echo "There are no matches."
                        return
                    fi 
                    printSelectedColumns "$selectTmpFile" "$metaPath" "${columnPart[@]}" 
                else 
                    echo There is an error with the provided columns name.
                fi 

            else
                if array1_in_array2 columnPart availableColumns;
                then 
                    echo ""
                    printSelectedColumns "$tablePath" "$metaPath" "${columnPart[@]}" 
                    echo ""
                else 
                    echo There is an error with the provided columns name.
                fi 
            fi 
        fi 

    else
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

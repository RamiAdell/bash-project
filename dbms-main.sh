#!/bin/bash

shopt -s extglob



# current selected database
currentDB="hello"
# current base directory for databases
baseDir="./Databases"


function array1_in_array2() {
    local -n array1="$1"   
    local -n array2="$2"   
    local -A set         

    for elemment in "${array2[@]}"; do
        set["$elemment"]=1
    done

    for elemment in "${array1[@]}"; do
        if [[ ! -v set["$elemment"] ]]; then
            return 1  
        fi
    done
    return 0  
}

function handleSelect() {
    local selectQuery="$1"
    clear 

    echo $selectQuery
    # Store the regex pattern in a variable
    local sql_regex='^[[:space:]]*(SELECT|select)[[:space:]]+(\*|([a-zA-Z_][a-zA-Z0-9_]*([[:space:]]*,[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*)*))[[:space:]]+(FROM|from)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]+(WHERE|where)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*((["'"'"']([^"'"'"'\\]|\\.)*["'"'"'])|([^[:space:];'"'"'"]+)))?[[:space:]]*;[[:space:]]*$'    
    if [[ "$selectQuery" =~ $sql_regex ]]; then
        
        local columnTempPart="${BASH_REMATCH[2]}"     # * or column list
        local tableName="${BASH_REMATCH[6]}"      # table name
        local whereKeyword="${BASH_REMATCH[8]}"   # WHERE keyword (if exists)
        local whereColumn="${BASH_REMATCH[9]}"    # column in WHERE
        local whereValue="${BASH_REMATCH[10]}"    # value in WHERE
        whereValue="${whereValue//\"/}"
        whereValue="${whereValue//\'/}"

        local tablePath="$baseDir/$currentDB/$tableName"
        local metaPath="$baseDir/$currentDB/.$tableName-metadata"

        local isSelectAll=0
        local hasWhere=0

        availableColumns=($(cut -d ':' -f1 "$metaPath"))
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
                fi

            else 
                cat $tablePath
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
                    declare -a colIndexes=()
                    for colName in "${columnPart[@]}"; do
                        index=$(grep -n "^$colName:" "$metaPath" | cut -d: -f1)
                        colIndexes+=("$index")
                    done

                    IFS=$'\n' sortedColIndexes=($(sort -n <<<"${colIndexes[*]}"))
                    unset IFS

                    awkCmd='BEGIN {FS=":"; OFS=":"} {'
                    for idx in "${sortedColIndexes[@]}"; do
                        awkCmd+="printf \"%s\", \$$idx; if (${idx} != ${sortedColIndexes[-1]}) printf OFS; "
                    done
                    awkCmd+='print ""}'

                    awk "$awkCmd" "$selectTmpFile"
                else 
                    echo There is an error with the provided columns name.
                fi 

            else
                if array1_in_array2 columnPart availableColumns;
                then 
                    declare -a colIndexes=()
                    for colName in "${columnPart[@]}"; do
                        index=$(grep -n "^$colName:" "$metaPath" | cut -d: -f1)
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


                    awk "$awkCmd" "$tablePath"
                else 
                    echo There is an error with the provided columns name.
                fi 
            fi 
        fi 


        # Display parsed information
        # echo "Table: $tableName"
        # echo "Is SELECT *: $isSelectAll"
        # echo "Columns: $columnPart"
        # echo "Has WHERE: $hasWhere"
        
        # if [[ $hasWhere -eq 1 ]]; then
        #     echo "WHERE column: $whereColumn"
        #     echo "WHERE value: $whereValue"
        # fi
        # echo "  SELECT * FROM table;"
    # echo "  SELECT col1,col2 FROM table;"
    # echo "  SELECT * FROM table WHERE col=val;"
    # echo "  SELECT col1 FROM table WHERE col2=val;"
    else
        echo "Invalid SELECT query format"
        echo "-------AVAILABLE FORMATS-------"
        echo "SELECT * FROM table;"
        echo "SELECT col1,col2... FROM table;"
        echo "SELECT * FROM table WHERE col=val;"
        echo "SELECT col1 FROM table WHERE col2=val;"
        return 1
    fi
}

# function printSelectedColumns(){
#     local columnPart=$1
#     local file=$2

#     declare -a colIndexes=()
#     for colName in "${columnPart[@]}"; do
#         index=$(grep -n "^$colName:" "$metaPath" | cut -d: -f1)
#         colIndexes+=("$index")
#     done

#     IFS=$'\n' sortedColIndexes=($(sort -n <<<"${colIndexes[*]}"))
#     unset IFS

#     awkCmd='BEGIN {FS=":"; OFS=":"} {'
#     for idx in "${sortedColIndexes[@]}"; do
#         awkCmd+="printf \"%s\", \$$idx; if (${idx} != ${sortedColIndexes[-1]}) printf OFS; "
#     done
#     awkCmd+='print ""}'

#     awk "$awkCmd" "$file"
# }

function handleDelete() {
    local deleteQuery="$1"

    if [[ "$deleteQuery" =~ ^(DELETE[[:space:]]+FROM|delete[[:space:]]+from)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]+(WHERE|where)[[:space:]]+(.+))?\;$ ]] 
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
        echo "Invalid DELETE syntax."
        echo "Accepted forms:"
        echo "  DELETE FROM table_name;"
        echo "  DELETE FROM table_name WHERE column=value;"
        echo "Only full lowercase or uppercase accepted."
    fi
}

function main(){
    echo "Welcome to oursql Engine!"
    PS3="Query: "
    while true 
    do 
        read -r query

        query=$(echo "$query" | sed 's/^[ \t]*//;s/[ \t]*$//')
        if [[ "$query" =~ ^[[:space:]]*(exit|quit)[[:space:]]*$ ]]; then
            echo "Exiting..."
            break
        fi
        cmd=$(echo "$query" | awk '{print toupper($1)}')
        case "$cmd" in
            SELECT)
                handleSelect "$query"
                ;;
            INSERT)
                handleInsert "$query"
                ;;
            DELETE)
                handleDelete "$query"
                ;;
            UPDATE)
                handleUpdate "$query"
                ;;
            DROP)
                handleDrop "$query"
                ;;
            *)
                echo "Invalid or unsupported SQL command."
                ;;
        esac
    done
}


main



# DELETE FROM table_name WHERE condition;
# DELETE * FROM table_name;
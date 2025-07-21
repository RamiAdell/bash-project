
insertInTable() {
    baseDir="./Databases"
    currentDB="$1"
    clear
    echo "INSERT DATA"
    echo ""

    # will add options to select database with select menu
    echo "Available Tables:"
    ls "$baseDir/$currentDB/" | grep -v '^\.' || { clear; echo "No tables found"; return; }

    read -p "Enter table name: " selectedTable

    metaDataFile="$baseDir/$currentDB/.$selectedTable-metadata"
    dataFile="$baseDir/$currentDB/$selectedTable"
    if [ ! -f "$dataFile" ]; then
        clear
        echo "Table '$selectedTable' not found."
        return
    fi
    if [ ! -f "$metaDataFile" ]; then
        echo "Metadata for table '$selectedTable' not found."
        return
    fi


    columnArray=()
    typeArray=()
    primaryKeyCol=""
    pkIndex=-1

    i=0

    while IFS=':' read -r col type pkFlag; do
        columnArray+=("$col")
        typeArray+=("$type")
        if [[ "$pkFlag" == "pk" ]]; then
            primaryKeyCol="$col"
            pkIndex=$i
        fi
        ((i++))
    done < "$metaDataFile"

    rowToAdd=""
    clear
    echo "Inserting data into table '$selectedTable' in database '$currentDB'."
    echo ""
    for ((j=0; j<${#columnArray[@]}; j++)); do
        colName="${columnArray[j]}"
        colType="${typeArray[j]}"

        while true; do
            read -p "Enter $colName ($colType): " value

            if ! validateDataType "$value" "$colType"; then
                continue
            fi

            if [[ $j -eq $pkIndex && -f "$dataFile" ]]; then
                # search if existing
                existing=$(cut -d':' -f$((pkIndex + 1)) "$dataFile" | grep -x "$value")
                if [[ -n "$existing" ]]; then
                    echo "Primary key '$value' already exists please enter a unique value."
                    continue
                fi
            fi

            break
        done

        # Append to row string
        if [[ $j -eq 0 ]]; then
            rowToAdd="$value"
        else
            rowToAdd="$rowToAdd:$value"
        fi
    done

    echo "$rowToAdd" >> "$dataFile"
    clear
    echo "Data inserted successfully into table '$selectedTable'."

}


validateDataType() {
    local value="$1"
    local dtype="$2"

    if [[ "$dtype" == "int" ]]; then
        if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
            echo "Invalid integer"
            return 1
        fi

    elif [[ "$dtype" == "float" ]]; then
        if [[ ! "$value" =~ ^-?[0-9]*\.[0-9]+$ && ! "$value" =~ ^-?[0-9]+$ ]]; then
            echo "Invalid float"
            return 1
        fi

    elif [[ "$dtype" == "character" ]]; then
        if [[ ! "$value" =~ ^.$ ]]; then
            echo "Invalid character"
            return 1
        fi

    elif [[ "$dtype" == "string" ]]; then
        return 0

    elif [[ "$dtype" == "email" ]]; then
        if [[ ! "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "Invalid email"
            return 1
        fi

    else
        echo "Unknown data type"
        return 1
    fi
}


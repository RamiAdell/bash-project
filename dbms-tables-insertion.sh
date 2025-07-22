insertInTable() {
    clear
    echo "INSERT DATA"
    echo ""

    tableList=()
    tableCount=0

    if [ -d "$baseDir/$selectedDB" ]; then
        echo "Available Tables:"
        for table in "$baseDir/$selectedDB/"*; do
            if [ -f "$table" ]; then
                tableCount=$((tableCount + 1))
                tableName=$(basename "$table")
                echo "$tableCount. $tableName"
                tableList+=("$tableName")
            fi
        done

        if [ ${#tableList[@]} -eq 0 ]; then
            echo "No tables found"
            return
        fi

        while true; do
            read -p "Select table by number: " tableChoice
            if [[ "$tableChoice" =~ ^[0-9]+$ ]] && [ "$tableChoice" -ge 1 ] && [ "$tableChoice" -le "${#tableList[@]}" ]; then
                index=$((tableChoice-1))
                selectedTable="${tableList[$index]}"
                metaDataFile="$baseDir/$selectedDB/.$selectedTable-metadata"
                dataFile="$baseDir/$selectedDB/$selectedTable"
                break
            else
                echo "Invalid selection. Try again."
            fi
        done

    else
        echo "Error: '$baseDir/$selectedDB' directory not found"
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
    
    echo "Inserting data into table '$selectedTable' in database '$selectedDB'."
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


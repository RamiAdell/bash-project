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
        echo "to go back to table operations menu, enter 0"

        if [ ${#tableList[@]} -eq 0 ]; then
            echo "No tables found"
            return
        fi

        while true; do
            read -p "Select table by number: " tableChoice
            if [[ "$tableChoice" -eq 0 ]]; then
            clear
                return
            fi
            if [[ "$tableChoice" =~ ^[0-9]+$ ]] && [ "$tableChoice" -ge 1 ] && [ "$tableChoice" -le "${#tableList[@]}" ]; then
                index=$((tableChoice-1))
                selectedTable="${tableList[$index]}"
                metaDataFile="$baseDir/$selectedDB/.$selectedTable-metadata"
                dataFile="$baseDir/$selectedDB/$selectedTable"
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

    tmpDataFile="/tmp/$(basename "$selectedTable")_$$"
    if [ -f "$dataFile" ]; then
        cp "$dataFile" "$tmpDataFile"
        if [ $? -ne 0 ]; then
            echo "Failed to copy file to temporary directory"
            return
        fi
    else
        touch "$tmpDataFile"
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

            if [[ $j -eq $pkIndex && -f "$tmpDataFile" ]]; then
                # search if existing
                existing=$(cut -d':' -f$((pkIndex + 1)) "$tmpDataFile" | grep -x "$value")
                if [[ -n "$existing" ]]; then
                    echo "Primary key '$value' already exists please enter a unique value."
                    continue
                fi
            fi

            break
        done

        if [[ $j -eq 0 ]]; then
            rowToAdd="$value"
        else
            rowToAdd="$rowToAdd:$value"
        fi
    done

    echo "$rowToAdd" >> "$tmpDataFile"
    
    mv "$tmpDataFile" "$dataFile"
    if [ $? -eq 0 ]; then
        clear
        echo "Data inserted successfully into table '$selectedTable'."
    else
        rm -f "$tmpDataFile"
    fi

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




updateInTable(){
    clear
    echo "UPDATE DATA"
    echo ""

    tableList=()
    tableCount=0

    if [ -d "$baseDir/$selectedDB" ]; then
        echo "Available Tables:"
        for table in "$baseDir/$selectedDB/"*; do
            if [ -f "$table" ] && [[ "$(basename "$table")" != .* ]]; then
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
        echo "Database not found"
        return
    fi

    tmpDataFile="/tmp/$(basename "$selectedTable")_$$"
    if [ -f "$dataFile" ]; then
        cp "$dataFile" "$tmpDataFile"
        if [ $? -ne 0 ]; then
            echo "failed to copy file to temporary directory"
            return
        fi
    else
        echo "no data file found for table '$selectedTable'"
        return
    fi
    # Read metadata
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

    echo ""
    read -p "Do you want to see all records first? (y/n): " showRecords
    if [[ "$showRecords" =~ ^[Yy]$ ]]; then
    clear
    echo ""
    echo "Current records in '$selectedTable':"
    echo "=================================="

    # Show column headers
    header="${columnArray[0]}"
    for ((i=1; i<${#columnArray[@]}; i++)); do
        header+=" | ${columnArray[i]}"
    done
    echo "$header"

    # Show separator line
    separator="--------------------------------"
 
    echo "$separator"

    # Show data rows
    if [ -f "$tmpDataFile" ]; then
        while IFS=':' read -r -a row; do
            line="${row[0]}"
            for ((i=1; i<${#row[@]}; i++)); do
                line+=" | ${row[i]}"
            done
            echo "$line"
        done < "$tmpDataFile"
    else
        echo "No data found in table."
    fi
    echo ""
fi


    while true; do
    
        read -p "Enter the $primaryKeyCol value of the row to update: " pkValue
        
        # check if the primary key exists in the table
        if [ -f "$tmpDataFile" ]; then
            rowNumber=$(awk -F':' -v pk="$pkValue" -v pkCol="$((pkIndex + 1))" '$pkCol == pk {print NR}' "$tmpDataFile")
            if [ -n "$rowNumber" ]; then
                # get the current row data
                currentRow=$(sed -n "${rowNumber}p" "$tmpDataFile")
                IFS=':' read -r -a currentValues <<< "$currentRow"
                break
            else
                echo "primary key '$pkValue' does not exist in table '$selectedTable'."
                read -p "Do you want to try again? (y/n): " tryAgain
                if [[ ! "$tryAgain" =~ ^[Yy]$ ]]; then
                    echo "Update cancelled."
                    return
                fi
            fi
        else
            echo "No data found in table '$selectedTable'."
            rm -f "$tmpDataFile"
            return
        fi
    done

 
    while true; do
    clear
    echo ""
    echo "Current values for record with $primaryKeyCol = '$pkValue':"
    echo "========================================="
    for ((i=0; i<${#columnArray[@]}; i++)); do
        echo "$((i+1)). ${columnArray[i]} (${typeArray[i]}): ${currentValues[i]}"
    done
    echo ""
        echo "Select column to update:"
        for ((i=0; i<${#columnArray[@]}; i++)); do
            echo "$((i+1)). ${columnArray[i]} (current: ${currentValues[i]})"
        done
        echo "S. Save changes and exit"
        echo ""
        
        read -p "Your choice: " columnChoice
        
        if [[ "$columnChoice" =~ ^[Ss]$ ]]; then
            mv "$tmpDataFile" "$dataFile"
            if [ $? -eq 0 ]; then
                clear
                echo "Changes saved successfully!"
            else
                clear
                echo "Failed to save changes."
                rm -f "$tmpDataFile"
            fi
            break
        elif [[ "$columnChoice" =~ ^[0-9]+$ ]] && [ "$columnChoice" -ge 1 ] && [ "$columnChoice" -le "${#columnArray[@]}" ]; then
            colIndex=$((columnChoice-1))
            selectedColumn="${columnArray[colIndex]}"
            selectedType="${typeArray[colIndex]}"
            
            
            if [ "$colIndex" -eq "$pkIndex" ]; then
                echo ""
                read -p "you are updating the primary key. Continue? (y/n): " confirmPK
                if [[ ! "$confirmPK" =~ ^[Yy]$ ]]; then
                    continue
                fi
            fi
            
            while true
            do
                echo ""
                read -p "Enter new value for $selectedColumn ($selectedType) [current: ${currentValues[colIndex]}]: " newValue
                
                # wrong input will be ignored
                if [ -z "$newValue" ]
                then
                    echo "Keeping current value: ${currentValues[colIndex]}"
                    break
                fi
                
                if [ ! validateDataType "$newValue" "$selectedType" ]
                then
                    echo "Invalid value for $selectedColumn. Please try again."
                    continue
                fi
                
                if [ "$colIndex" -eq "$pkIndex" ] && [ "$newValue" != "${currentValues[colIndex]}" ]
                then
                existing=$(awk -F':' -v pk="$newValue" -v pkCol="$((pkIndex + 1))" '$pkCol == pk {print NR}' "$tmpDataFile")
                if [ -n "$existing" ]; then
                    echo "Primary key '$newValue' already exists. Please enter a unique value."
                    continue
                fi
                fi
                
                currentValues[colIndex]="$newValue"
                newRow="${currentValues[0]}"
                for ((j=1; j<${#currentValues[@]}; j++)); do
                    newRow="$newRow:${currentValues[j]}"
                done
                sed -i "${rowNumber}s/.*/$newRow/" "$tmpDataFile"
                
                echo "Updated $selectedColumn to '$newValue'"
                break
            done
        else
            echo "Invalid selection, Try again."
        fi
        echo ""
    done
}
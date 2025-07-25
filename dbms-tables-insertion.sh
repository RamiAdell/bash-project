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
            echo ""
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

showTable(){
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
    echo "--------------------------------"

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
        echo ""
        echo "to go back to table operations menu, enter 0"

        if [ ${#tableList[@]} -eq 0 ]; then
            echo "No tables found"
            return
        fi

        while true; do
    
            echo ""
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

    clear
    echo "Selected table: $selectedTable"
    echo ""
    echo "Select update mode:"
    echo "1. Update specific row by primary key"
    echo "2. Update multiple rows by condition"
    echo ""

    while true; do
        read -p "Select update mode (0 to go back): " updateMode
        if [[ "$updateMode" == "1" ]]; then
        clear
            echo "Update specific row by primary key"
            showTable
            break
        elif [[ "$updateMode" == "0" ]]; then
            clear
            return
        elif [[ "$updateMode" == "2" ]]; then
        clear
            echo "Update multiple rows by condition"
            echo ""
            showTable
            echo ""
            echo "Select column to filter by:"
            for ((i=0; i<${#columnArray[@]}; i++)); do
                echo "$((i+1)). ${columnArray[i]}"
            done
            echo ""
            
            while true; do
                read -p "Select column to filter by (number): " filterColChoice
                if [[ "$filterColChoice" =~ ^[0-9]+$ ]] && [ "$filterColChoice" -ge 1 ] && [ "$filterColChoice" -le "${#columnArray[@]}" ]; then
                    filterColIndex=$((filterColChoice-1))
                    filterColumn="${columnArray[filterColIndex]}"
                    break
                else
                    echo "Invalid selection. Try again."
                fi
            done
            
            echo ""
            read -p "Enter value to find in column '$filterColumn': " filterValue
            clear

            # Find matching rows
            matchingRows=()
            rowCount=0
            while IFS=':' read -r -a row; do
                rowCount=$((rowCount + 1))
                if [ "${row[filterColIndex]}" == "$filterValue" ]; then
                    matchingRows+=("$rowCount")
                fi
            done < "$tmpDataFile"
            
            if [ ${#matchingRows[@]} -eq 0 ]; then
                echo "No rows found with '$filterColumn' = '$filterValue'"
                return
            fi
            
            echo "Found ${#matchingRows[@]} row(s) with '$filterColumn' = '$filterValue'"
            echo ""
            
            # Select column to update
            echo "Select column to update:"
            for ((i=0; i<${#columnArray[@]}; i++)); do
                echo "$((i+1)). ${columnArray[i]} (${typeArray[i]})"
            done
            echo ""
            
            while true; do
                read -p "Select column to update (number): " updateColChoice
                if [[ "$updateColChoice" =~ ^[0-9]+$ ]] && [ "$updateColChoice" -ge 1 ] && [ "$updateColChoice" -le "${#columnArray[@]}" ]; then
                    updateColIndex=$((updateColChoice-1))
                    updateColumn="${columnArray[updateColIndex]}"
                    updateType="${typeArray[updateColIndex]}"
                    break
                else
                    echo "Invalid selection. Try again."
                fi
            done
            
            echo ""
            while true; do
                read -p "Enter new value for '$updateColumn': " newValue
                
                if ! validateDataType "$newValue" "$updateType"; then
                    echo "Invalid value for $updateColumn ($updateType). Please try again."
                    continue
                fi
                
                # check for primary key uniqueness if updating primary key
                if [ "$updateColIndex" -eq "$pkIndex" ]; then
                    existing=$(awk -F':' -v pk="$newValue" -v pkCol="$((pkIndex + 1))" '$pkCol == pk {print NR}' "$tmpDataFile")
                    if [ -n "$existing" ]; then
                        echo "Primary key '$newValue' already exists. Cannot update multiple rows to same primary key value."
                        continue
                    fi
                fi
                break
            done
            
            echo ""
            echo "Summary: Update '$updateColumn' = '$newValue' where '$filterColumn' = '$filterValue'"
            echo "Affected rows: ${#matchingRows[@]}"
            echo ""
            read -p "Proceed? (y/n): " confirm
            
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                for rowNum in "${matchingRows[@]}"; do
                    currentRow=$(sed -n "${rowNum}p" "$tmpDataFile")
                    IFS=':' read -r -a currentValues <<< "$currentRow"
                    currentValues[updateColIndex]="$newValue"
                    
                    newRow="${currentValues[0]}"
                    for ((j=1; j<${#currentValues[@]}; j++)); do
                        newRow="$newRow:${currentValues[j]}"
                    done
                    sed -i "${rowNum}s/.*/$newRow/" "$tmpDataFile"
                done
                
                mv "$tmpDataFile" "$dataFile"
                if [ $? -eq 0 ]; then
                    clear
                    echo "Updated ${#matchingRows[@]} rows successfully!"
                    echo ""
                    
                    # Show updated table
                    echo "Updated records in '$selectedTable':"
                    echo "=================================="
                    
                    # Show column headers
                    header="${columnArray[0]}"
                    for ((i=1; i<${#columnArray[@]}; i++)); do
                        header+=" | ${columnArray[i]}"
                    done
                    echo "$header"
                    echo "--------------------------------"
                    
                    # Show data rows
                    while IFS=':' read -r -a row; do
                        line="${row[0]}"
                        for ((i=1; i<${#row[@]}; i++)); do
                            line+=" | ${row[i]}"
                        done
                        echo "$line"
                    done < "$dataFile"
                else
                    echo "Failed to save changes."
                    rm -f "$tmpDataFile"
                fi
            else
                echo "Update cancelled."
                rm -f "$tmpDataFile"
            fi
            return
        else
            echo "Invalid selection. Please enter 1 or 2."
        fi
    done

    while true; do
        
        read -p "Enter the $primaryKeyCol value of the row to update: " pkValue
        
        # check if the primary key exists in the table
        if [ -f "$tmpDataFile" ]
        then
            rowNumber=$(awk -F':' -v pk="$pkValue" -v pkCol="$((pkIndex + 1))" '$pkCol == pk {print NR}' "$tmpDataFile")
            if [ -n "$rowNumber" ]
            then
            # get the current row data
            currentRow=$(sed -n "${rowNumber}p" "$tmpDataFile")
            IFS=':' read -r -a currentValues <<< "$currentRow"
            break
            else
                echo "primary key '$pkValue' does not exist in table '$selectedTable'."
                read -p "Do you want to try again? (y/n): " tryAgain
                
                if [[ ! "$tryAgain" =~ ^[Yy]$ ]]
                then
                echo "Update cancelled."
                return
                fi
              
                fi
        else
            echo "No data found in table '$selectedTable'"
            rm -f "$tmpDataFile"
            return
        fi
    done

 
    while true
    do
    clear
    echo ""
    echo "Current values for record with $primaryKeyCol = '$pkValue':"
    echo "========================================="

        echo ""
        echo "Select column to update:"
        echo ""

        for ((i=0; i<${#columnArray[@]}; i++))
        do
            echo "$((i+1)). ${columnArray[i]} (current: ${currentValues[i]})"
        done

        echo ""
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
                read -p "you are updating the primary key. Do you want to continue? (y/n): " confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
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
                
                if ! validateDataType "$newValue" "$selectedType" 
                then
                    echo "Invalid value for $selectedColumn. Please try again."
                    continue
                fi
                
                if [ "$colIndex" -eq "$pkIndex" ] && [ "$newValue" != "${currentValues[colIndex]}" ]
                then
                existing=$(awk -F':' -v pk="$newValue" -v pkCol="$((pkIndex + 1))" '$pkCol == pk {print NR}' "$tmpDataFile")
                if [ -n "$existing" ]; then
                    echo "Primary key '$newValue' already exists. enter a unique value."
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
#!/bin/bash

shopt -s extglob

baseDir="./Databases"


function createTable(){
    clear
    dataTypes=("int" "float" "character" "string" "email" )
    while true
    do 
        echo ""
        read -p "Enter the table name: (write $ to quit) " tableName
        echo ""

        if [[ -f "$baseDir/$selectedDB/$tableName" ]]
        then 
            echo "Table $tableName already exists. Please choose another name."
            continue
        
        elif [[ -z "$tableName" ]]
        then 
            echo "Table name cannot be empty. Please try again."
            continue
        elif [[ "$tableName" == "\$" ]]
        then 
        clear
            return     
        elif [[ ! "$tableName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
        then     
            echo "Table name must start with a letter or underscore and contain only letters, digits, or underscores."
            continue
        else 
            break
        fi 
    done
    
    pkFlag=1
    
    while true 
    do 
        read -p "Enter the number of columns(Maximum 5 digits): " columns
        if [[ $columns =~ ^[0-9]{1,5}$ ]]
        then 
            break
        else
            echo Invalid input. Please enter a valid 5 digits number.
        fi
    done
    tempMetaFile=$(mktemp)
    for (( i=0; i<columns ; i++ ))
    do  
        clear 
        readColumnName $i "$tempMetaFile"
        readDataTypes
        if [[ $pkFlag -eq 1 ]]
        then 
            read -p "Do you want to make this column as a primary key? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]
            then
                pkColumn="pk"
                pkFlag=0
            fi
        else
            pkColumn=""
        fi 
        echo "$columnName:$colDataType:$pkColumn" >> "$tempMetaFile"
    done
    cp "$tempMetaFile" "$baseDir/$selectedDB/.${tableName}-metadata"
    touch "$baseDir/$selectedDB/$tableName"
    rm "$tempMetaFile"
    clear
    echo "Table '$tableName' created successfully in database '$selectedDB'."

}

function readDataTypes(){
    while true
    do 
        echo "Select $columnName data type: "
        select dataType in "${dataTypes[@]}"
        do 
            case $REPLY in 
            1|2|3|4|5 ) 
                colDataType="${dataTypes[$((REPLY-1))]}"
                break
                ;;
            *)
                echo "Invalid choice."
                continue
            esac
        done
        break 
    done 
}
function readColumnName(){
    colIdx=$1
    tempMetaFile=$2
    while true
    do 
        read -p "Enter the column $((colIdx+1)) name: " columnName
        echo ""
        if cut -d ':' -f1 "$tempMetaFile" | grep -xq "$columnName" 
        then
            echo "Column $columnName already exists. Please choose another name."
            continue
        
        elif [[ -z "$columnName" ]]
        then 
            echo "Column name cannot be empty. Please try again."
            continue  
        elif [[ ! "$columnName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
        then     
            echo "Column name must start with a letter or underscore and contain only letters, digits, or underscores."
            continue
        else 
            break
        fi 
    done
}

function listTables(){
    clear
    tableNames=()
    for table in "$baseDir/$selectedDB"/*; do
        [[ -f "$table" ]] && tableNames+=("$(basename "$table")")
    done

    if [[ ${#tableNames[@]} -eq 0 ]]; then
        echo "No available tables"
    else
        echo ""
        echo Available Tables: 
        echo "${tableNames[*]}" | sed 's/ /, /g'
    fi
}

function listTablesPreProcess(){
    tableList=("$baseDir/$selectedDB"/*)
    tableNames=()
    for table in "${tableList[@]}"
    do 
        if [[ -f $table ]] 
        then  
            tableName=`basename $table`
            tableNames+=("$tableName")
        fi 
    done
    if [[ ${#tableNames[@]} -eq 0 ]]; then
        echo "No tables found in database $selectedDB"
        echo "Exiting...."
        return
    fi

    tableNames+=("--Back to table operations Menu--")
}
function dropTable(){
    PS3="Enter the Table number to drop: "
    while true
    do 
        listTablesPreProcess
        select tableName in "${tableNames[@]}"
        do
            if [[ "$REPLY" -eq "${#tableNames[@]}" ]]
            then
                echo No tables found in database $selectedDB
                echo Exiting....
                PS3="Enter a valid number to proceed: "
                return 
            fi
            if [[ -n "$tableName" ]]; then
                read -p "Are you sure you want to delete '$tableName'? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]
                then
                    rm -rf "$baseDir/$selectedDB/$tableName" "$baseDir/$selectedDB/.${tableName}-metadata"
                    echo "Tabel '$tableName' deleted successfully."
                else
                    echo "Deletion cancelled."
                fi
                break
            else
                echo "Invalid choice. Try again."
            fi
        done

    done
}

function deleteInTable(){
    clear
    echo "DELETE DATA"
    echo ""
    deleteAllFlag=1
    deleteoneFlag=0
    while true
    do 
        select choice in "Delete all table?" "Delete one record from table?" "Delete all records from table WHERE condition?" "--Back to table operations Menu--"
        do 
            case $REPLY in 
            1)
                deleteAllTable
                break
                ;;
            2)
                deleteFromTable $deleteoneFlag
                break
                ;;
            3)
                deleteFromTable $deleteAllFlag
                break
                ;;
            4)
                return 
                ;;
            *)
                echo Invalid choice.
                ;;
            esac
        done 

    done 
}

function deleteAllTable(){
    PS3="Enter the Table number to delete: "
    clear 
    while true
    do 
        listTablesPreProcess
        select tableName in "${tableNames[@]}"
        do
            if [[ "$REPLY" -eq "${#tableNames[@]}" ]]
            then
                clear
                echo No tables found in database $selectedDB
                echo Exiting....
                PS3="Enter a valid number to proceed: "
                return 
            fi
            if [[ -n "$tableName" ]]; then
                read -p "Are you sure you want to delete '$tableName'? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]
                then
                    clear 
                    echo "" > "$baseDir/$selectedDB/$tableName"
                    echo "Tabel '$tableName' content deleted successfully."
                else
                    echo "Deletion cancelled."
                fi
                break
            else
                echo "Invalid choice. Try again."
            fi
        done
        break
    done

}

function deleteFromTable() {
    listTablesPreProcess
    PS3="Enter the Table number to delete from: "
    clear 
    deleteFlag=$1
    echo "Available Tables:"
    select tableName in "${tableNames[@]}"; do
        if [[ -z "$tableName" ]]; then
            echo "Invalid choice. Try again."
            continue
        fi

        tablePath="$baseDir/$selectedDB/$tableName"
        metaPath="$baseDir/$selectedDB/.$tableName-metadata"

        if [[ ! -f "$tablePath" || ! -s "$metaPath" ]]; then
            echo "Table or its metadata doesn't exist or is empty."
            return
        fi
        clear 
        echo -e "\nAvailable columns:"
        columns=($(cut -d ':' -f1 "$metaPath"))

        i=1
        for col in "${columns[@]}"
        do 
            echo "Column $i: $col"
            ((i++))
        done

        read -p "Enter the column name to use in WHERE condition: " colName
        colIndex=$(grep -n "^$colName:" "$metaPath" | cut -d: -f1)

        if [[ -z "$colIndex" ]]; then
            echo "Column not found."
            return
        fi

        read -p "Enter the value to match for deletion: " targetValue

        matchingRows=$(awk -F: -v col="$colIndex" -v val="$targetValue" '$col == val {print NR ": " $0}' "$tablePath")
        matchingCount=$(echo "$matchingRows" | grep -c '^')
        if [[ -z "$matchingRows" ]]; then
            clear 
            echo "No matching rows found."
            return
        fi
        clear 
        echo -e "\nMatching rows:"
        echo "$matchingRows"
        if [[ $deleteFlag -eq 1 ]]; then
            echo -e "\nDeleting all $matchingCount matching rows..."
            # Delete from bottom to top to preserve the row number 
            echo "$matchingRows" | cut -d: -f1 | sort -rn | while read -r lineNum; do
                sed -i "${lineNum}d" "$tablePath"
            done
            
            echo "All matching rows deleted."

        elif [[ $deleteFlag -eq 0 ]]
        then 
            read -p "Enter the row number to delete (or 0 to cancel): " rowNum

            if [[ "$rowNum" == "0" ]]; then
                echo "Deletion cancelled."
                return
            fi

            totalLines=$(wc -l < "$tablePath")
            if (( rowNum > totalLines || rowNum < 1 )); then
                echo "Invalid row number."
                return
            fi

            sed -i "${rowNum}d" "$tablePath"
            clear 
            echo "Row $rowNum deleted successfully."
        fi 
        break 
    done
}


showTableData() {

    clear
    echo ""
    echo "SHOWING DATA"
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
                break
            fi
        done

    else
        echo "Database not found"
        return
    fi

    if [ ! -f "$dataFile" ] || [ ! -f "$metaDataFile" ]
    then
    echo "file missing for '$selectedTable'."
    return
    fi
    clear
    echo ""
    echo "Rows in '$selectedTable':"
    echo "-----------------------------"

    columnNames=()
    while IFS=':' read -r name _ _; do
        columnNames+=("$name")
    done < "$metaDataFile"

    headerLine="${columnNames[0]}"
    for ((i=1; i<${#columnNames[@]}; i++)); do
        headerLine+=" | ${columnNames[i]}"
    done

    
    echo "$headerLine"
    echo "-----------------------------"

    while IFS=':' read -r -a row; do
        echo "${row[0]}" | tr -d '\n'
        for ((i=1; i<${#row[@]}; i++)); do
            echo -n " | ${row[i]}"
        done
        echo ""
    done < "$dataFile"

    echo ""
}

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
            break    
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
    touch "$baseDir/$selectedDB/.${tableName}-metadata"
    for (( i=0; i<columns ; i++ ))
    do 
        readColumnName $i
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
        echo "$columnName:$colDataType:$pkColumn" >> "$baseDir/$selectedDB/.${tableName}-metadata"
        touch "$baseDir/$selectedDB/$tableName" 
    done
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
    while true
    do 
        read -p "Enter the column $((colIdx+1)) name: " columnName
        echo ""
        if cut -d ':' -f1 "$baseDir/$selectedDB/.${tableName}-metadata" | grep -xq "$columnName" 
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
    while true
    do 
        select choice in "Delete all table?" "Delete from table?" "--Back to table operations Menu--"
        do 
            case $REPLY in 
            1)
                deleteAllTable
                break
                ;;
            2)
                deleteFromTable
                break
                ;;
            3)
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
    listTablesPreProcess
    PS3="Enter the Table number to delete: "
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

# function deleteFromTable(){
    
# }
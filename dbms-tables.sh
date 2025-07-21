#!/bin/bash

shopt -s extglob

baseDir="./Databases"


function createTable(){
    selectedDB=$1
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
    touch "$baseDir/$selectedDB/$tableName" 
    
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
    done

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
        if cut -d ':' -f1 "$baseDir/$selectedDB/$tableName" | grep -xq "$columnName" 
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
    selectedDB=$1
    if [[ `ls -A $baseDir/$selectedDB` ]]
    then 
        echo "Available tables in database "$selectedDB": " `ls -p $baseDir/$selectedDB | grep -v /`
    else
        echo "No available tables in database "$selectedDB". "
    fi 
}
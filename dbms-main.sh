#!/bin/bash

shopt -s extglob
# current selected database
currentDB=""
# current base directory for databases
baseDir="./Databases"

initialize_application() {
    if [ ! -d "$baseDir" ]; then
        mkdir -p "$baseDir"
    fi
}

options=("Create Database" "List Databases" "Connect to Databases" "Drop Database" "Exit")


function createDB(){

while true; do

read -p "Enter database name: " dbName

if [ -d "$baseDir/$dbName" ]; then
    echo "Database '$dbName' already exists. Please choose another name."
    continue
fi

if [ -z "$dbName" ]; then
    echo "Database name cannot be empty. Please try again."
    continue
fi

if [[ ! "$dbName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Database Must start with a letter or underscore and contain only letters, digits, or underscores."
    continue
fi


mkdir -p "$baseDir/$dbName"
clear
echo "Database name '$dbName' is Created."
break
done

}

function listDB(){
    if [[ `ls -A $baseDir` ]]
    then 
        echo Available databases: `ls $baseDir`
    else
        echo No available databases 
    fi
}
function connectDB(){   
    clear

    echo "DATABASE SELECTION"

    dbList=""
    dbCount=0
    
    if [ -d "$baseDir" ]; then
        for db in `$baseDir/*`; do
            if [ -d "$db" ]; then
                dbCount=$((dbCount + 1))
                dbName=$(basename "$db")
                echo "$dbCount. $dbName"
                if [ -z "$dbList" ]; then
                    dbList="$dbName"
                else
                    dbList="$dbList $dbName"
                fi
            fi
        done
    fi
    
    if [ $dbCount -eq 0 ]; then
        echo "No databases"
    fi
    

    read -p "Enter database number to select, or 'new' to create new database: " choice 
    
    if [ "$choice" = "new" ]; then
        createDB
    else        
        dbArray=($dbList)

        if [ "$choice" -ge 1 ] && [ "$choice" -le $dbCount ]; then
            currentDB="${dbArray[$((choice-1))]}"
            clear
            echo "Database '$currentDB' selected"
        else
            echo "Invalid selection"
        fi
    fi

}


function dropDB(){
    while true; do
    read -p "Enter the Database you want to delete: " dbName

    if [[ -d  "$baseDir/$dbName" ]]
    then
        rm -rf $baseDir/$dbName
        echo "Database $dbName is deleted successfully."
        break
    else
        echo There are no database with the name $dbName
    fi
    done
}


function print_DBmenu(){
    
    while true; do
    PS3="Enter a valid number to proceed: "
        select option in "${options[@]}"
        do 
            case $REPLY in 
            1)
                createDB 
                break
                ;;
            2)
                listDB
                break
                ;;
            3) 
                connectDB
                break
                ;;
            4)
                dropDB
                break
                ;;
            5)
                exitd
                ;;
            *)
                echo Enter a number from 1 to 5 to continue
                break
                ;;
            esac
        done   
    done
}

initialize_application
print_DBmenu



#!/bin/bash

shopt -s extglob
# current selected database
CurrentDB=""
# current base directory for databases
BaseDir="./databases"

initialize_application() {
    if [ ! -d "$BaseDir" ]; then
        mkdir -p "$BaseDir"
    fi
}

options=("Create Database" "List Databases" "Connect to Databases" "Drop Database" "Exit")


function createDB(){

while true; do

read -p "Enter database name: " DBName

if [ -d "databases/$DBName" ]; then
    echo "Database '$DBName' already exists. Please choose another name."
    continue
fi

if [ -z "$DBName" ]; then
    echo "Database name cannot be empty. Please try again."
    continue
fi

if [[ ! "$DBName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Database Must start with a letter or underscore and contain only letters, digits, or underscores."
    continue
fi


mkdir -p "$BaseDir/$DBName"
clear
echo "Database name '$DBName' is Created."
break
done

}

function listDB(){
    if [[ `ls -A $BASE_DIR` ]]
    then 
        echo Available databases: `ls $BASE_DIR`
    else
        echo No available databases 
    fi
}
function connectDB(){   
    echo hello from createDB
}
function dropDB(){
    read -p "Enter the Database you want to delete: " dbName

    if [[ -d ./Databases/$dbName ]]
    then
        rm -rf ./Databases/$dbName
        echo "Database $dbName is deleted successfully."
    else
        echo There are no database with the name $dbName
    fi
}


function print_DBmenu(){
    PS3="Enter a valid number to proceed: "
    select option in "${options[@]}"
    do 
        case $REPLY in 
        1)
            createDB 
            ;;
        2)
            listDB
            ;;
        3) 
            connectDB
            ;;
        4)
            dropDB
            ;;
        5)
            exit
            ;;
        *)
            echo Enter a number from 1 to 5 to continue
        esac
    done   
}

initialize_application
print_DBmenu



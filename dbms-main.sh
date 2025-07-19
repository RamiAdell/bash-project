#!/bin/bash

shopt -s extglob
# current selected database
CURRENT_DB=""
# current base directory for databases
BASE_DIR="./databases"

initialize_application() {
    if [ ! -d "$BASE_DIR" ]; then
        mkdir -p "$BASE_DIR"
    fi
}

options=("Create Database" "List Databases" "Connect to Databases" "Drop Dataase" "Exit")


function createDB(){
    echo hello from createDB
}
function listDB(){
    echo hello from createDB
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



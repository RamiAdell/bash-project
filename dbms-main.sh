#!/bin/bash

shopt -s extglob

source ./common.sh
source ./dbms-tables.sh
source ./dbms-tables-insertion.sh
source ./dbms-database-functions.sh

# current selected database
currentDB=""
export currentDB

# current base directory for databases
baseDir="./Databases"
export baseDir

dbOptions=("Create Database" "List Databases" "Connect to Databases" "Drop Database" "Exit")



function print_DBmenu(){
    while true; do
    echo ""
    echo "Main Menu:"
    PS3="Enter a valid number to proceed: "
        select option in "${dbOptions[@]}"
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
                exit
                ;;
            *)
                clear
                echo "Enter a number from 1 to 5 to continue"
                break
                ;;
            esac
        done 
    done
}
        

initialize_application
print_DBmenu
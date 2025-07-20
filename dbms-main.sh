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
while true; do

    dbList=()
    dbCount=0

    if [ -d "$baseDir" ]; then
        echo "Available Databases:"
        for db in "$baseDir"/*; do
            if [ -d "$db" ]; then
                dbCount=$((dbCount + 1))
                dbName=$(basename "$db")
                echo "$dbCount. $dbName"
                dbList+=("$dbName")
            fi
        done

        if [ ${#dbList[@]} -eq 0 ]; then
            echo "No databases found"
            break
        fi

        read -p "Enter database number to select or 'new' to create new database: " choice
        if [[ "$choice"="new" ]]; then
        createDB
        continue
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#dbList[@]}" ]; then
            index=$((choice-1))
            selectedDB="${dbList[$index]}"
            clear
            # will put here list of database openrations
            echo "You selected: $selectedDB"
        else
            echo "Invalid selection."
            
        fi

    else
        echo "Error: Directory '$baseDir' does not exist."
        exit 1
    fi

    done
}


function dropDB(){
    PS3="Enter the DB number to drop: "
    dbList=("$baseDir"/*)
    if [[ ${#dbList[@]} -eq 0 ]]; then
        echo "No databases found in $baseDir"
        return
    fi
    dbNames=()
    for db in "${dbList[@]}"
    do 
        if [[ -d $db ]] 
        then  
            dbName=`basename $db`
            dbNames+=("$dbName")
        fi 
    done

    dbNames+=("--Exit from Drop Menu--")

    while true
    do 
        select dbName in "${dbNames[@]}"
        do
            if [[ "$REPLY" -eq "${#dbNames[@]}" ]]
            then 
                echo Exiting....
                PS3="Enter a valid number to proceed: "
                return 
            fi
            if [[ -n "$dbName" ]]; then
                read -p "Are you sure you want to delete '$dbName'? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]
                then
                    rm -rf "$baseDir/$dbName"
                    echo "Database '$dbName' deleted successfully."
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


function print_DBmenu(){
    
    while true; do
    echo ""
    echo "Main Menu:"
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



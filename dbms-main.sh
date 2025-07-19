#!/bin/bash

shopt -s extglob

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
    echo hello from createDB
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


print_DBmenu



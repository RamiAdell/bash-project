#!/bin/bash
function validateDataType() {
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

function checkPrimaryKeyDuplicate() {
    local tablePath="$1"
    local metaPath="$2"
    local pkColumn="$3"
    local pkValue="$4"
    local excludeRowNum="$5"  # Optional: exclude this row number (for updates)
    
    # Find the primary key column index
    local pkIndex=$(grep -n "^$pkColumn:" "$metaPath" | cut -d: -f1)
    if [[ -z "$pkIndex" ]]; then
        return 0  # No PK column found, no duplicate check needed
    fi
    
    # Check for duplicates
    local duplicateRows
    if [[ -n "$excludeRowNum" ]]; then
        duplicateRows=$(awk -F: -v col="$pkIndex" -v val="$pkValue" -v exclude="$excludeRowNum" 'NR != exclude && $col == val {print NR}' "$tablePath")
    else
        duplicateRows=$(awk -F: -v col="$pkIndex" -v val="$pkValue" '$col == val {print NR}' "$tablePath")
    fi
    
    if [[ -n "$duplicateRows" ]]; then
        pkValue=$(decodeString "$pkValue")
        echo "Primary key violation: Value '$pkValue' already exists in column '$pkColumn'"
        return 1
    fi
    
    return 0
}
function array1_in_array2() {
    local -n array1="$1"   
    local -n array2="$2"   
    local -A set         

    for elemment in "${array2[@]}"; do
        set["$elemment"]=1
    done

    for elemment in "${array1[@]}"; do
        if [[ ! -v set["$elemment"] ]]; then
            return 1  
        fi
    done
    return 0  
}
function initialize_application() {
    if [ ! -d "$baseDir" ]; then
        mkdir -p "$baseDir"
    fi
}
# Encode a string using Base64
function encodeString() {
    echo -n "$1" | base64
}

# Decode a Base64 string
function decodeString() {
    echo "$1" | base64 --decode
}
printDecodedFileN() {
    local filePath="$1"
    while IFS= read -r line; do
        # Separate line number and data
        rowNum="${line%%:*}"            # Gets part before the first colon
        encodedData="${line#*: }"       # Gets everything after "rowNum: "

        # Split encoded data into fields
        IFS=':' read -ra fields <<< "$encodedData"

        for i in "${!fields[@]}"; do
            decoded=$(echo "${fields[$i]}" | base64 --decode 2>/dev/null)
            # Add quotes around string/email values (optional logic, adjust if needed)
            if [[ "$decoded" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                fields[$i]="\"$decoded\""
            elif [[ "$decoded" =~ ^[a-zA-Z]+$ ]]; then
                fields[$i]="\"$decoded\""
            else
                fields[$i]="$decoded"
            fi
        done

        # Reconstruct line with row number
        (IFS=':'; echo "$rowNum: ${fields[*]}")
    done < "$filePath"
}

printDecodedFile() {
    local filePath="$1"
    local metaPath="$2"
    mapfile -t colTypes < <(cut -d: -f2 "$metaPath")

    # Read and process each line in the table
    while IFS= read -r line; do
        IFS=':' read -ra fields <<< "$line"
        for i in "${!fields[@]}"; do
            decoded=$(echo "${fields[$i]}" | base64 --decode)
            case "${colTypes[$i]}" in
                string|email)
                    fields[$i]="\"$decoded\""
                    ;;
                *)
                    fields[$i]="$decoded"
                    ;;
            esac
        done
        (IFS=:; echo "${fields[*]}")
    done < "$filePath"
    echo ""
}

# Export currentDB if set, but do not initialize here to avoid overwriting
export currentDB
export baseDir
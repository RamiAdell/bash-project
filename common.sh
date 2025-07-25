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
        echo "Primary key violation: Value '$pkValue' already exists in column '$pkColumn'"
        return 1
    fi
    
    return 0
}

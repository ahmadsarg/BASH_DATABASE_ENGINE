#! /usr/bin/bash
LC_COLLATE=C #To make the Terminal Case Senstive
shopt -s extglob #Enable Sub Pattern
export PS3="$1 >>"

function check_table_name() {
    if [[ $1 = [0-9]* ]]; then
        echo "Error 0x0014 : Table name can't start with a number."
        return 1
    else
        case $1 in
            +([a-zA-Z_0-9]))
                return 0
                ;;
            *)
                echo "Error 0x0015 : Table name can't contain special characters."
                return 1
                ;;
        esac
    fi
}

function check_col_name() {
    if [[ $1 = [0-9]* ]]; then
        echo "Error 0x0017 : Column name can't start with a number."
        return 1
    else
        case $1 in
            +([a-zA-Z_0-9]))
                return 0
                ;;
            *)
                echo "Error 0x0018 : Column name can't contain special characters."
                return 1
                ;;
        esac
    fi
}

function check_datatype() {
    local coltype=$1
    local value=$2

    if [[ $coltype == 'int' ]]; then
        if [[ $value =~ ^[0-9]+$ ]]; then
            return 0
        else
            echo "Error 0x0020: Value '$value' is not a valid integer."
            return 1
        fi
    elif [[ $coltype == 'str' ]]; then
        if [[ $value =~ ^[a-zA-Z]+$ ]]; then
            return 0
        else
            echo "Error 0x0021: Value '$value' is not a valid string."
            return 1
        fi
    else
        echo "Error 0x0022: Unknown column type '$coltype'."
        return 1
    fi
}

function check_primary_key() {
    local pk_value=$1
    local tbname=$2

    if grep -q "^$pk_value:" $HOME/.Amrdb/$dbname/$tbname; then
        echo "Error 0x0023: Primary key '$pk_value' already exists."
        return 1
    else
        return 0
    fi
}

read -r -p "Enter Table Name: " tbname
tbname=$(echo $tbname | tr ' ' '_') # Replace any space with '_'
check_table_name $tbname

if (( $? == 0 )); then
    if [[ -f $HOME/.Amrdb/$dbname/$tbname ]]; then
        # Read metadata to get column names and types
        col_names=($(awk -F: 'NR==1 {for (i=1; i<=NF; i++) print $i}' $HOME/.Amrdb/$dbname/metadata_$tbname))
        col_types=($(awk -F: 'NR==2 {for (i=1; i<=NF; i++) print $i}' $HOME/.Amrdb/$dbname/metadata_$tbname))

        # Prompt user for values
        col_values=()
        for i in "${!col_names[@]}"; do
            while true; do
                read -r -p "Enter value for ${col_names[$i]} (${col_types[$i]}): " value
                if check_datatype "${col_types[$i]}" "$value"; then
                    # Check primary key constraint for the first column
                    if (( i == 0 )); then
                        if check_primary_key "$value" "$tbname"; then
                            col_values+=("$value")
                            break
                        fi
                    else
                        col_values+=("$value")
                        break
                    fi
                fi
            done
        done

        # Insert the new row into the table
        new_row=$(IFS=:; echo "${col_values[*]}")
        echo "$new_row" >> $HOME/.Amrdb/$dbname/$tbname
        echo "Row inserted successfully."
    else
        echo "Error 0x0016 : 404 Table not found :)"
    fi
fi
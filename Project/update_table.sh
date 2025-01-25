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


read -r -p "Enter Table Name: " tbname
tbname=$(echo $tbname | tr ' ' '_') # Replace any space with '_'
check_table_name $tbname

if (( $? == 0 )); then
    if [[ -f $HOME/.Amrdb/$dbname/$tbname ]]; then
        # Read metadata to get column names and types
        col_names=($(awk -F: 'NR==1 {for (i=1; i<=NF; i++) print $i}' $HOME/.Amrdb/$dbname/metadata_$tbname))
        col_types=($(awk -F: 'NR==2 {for (i=1; i<=NF; i++) print $i}' $HOME/.Amrdb/$dbname/metadata_$tbname))

        # Prompt user for the condition column and value
        read -r -p "Enter condition column name: " condition_col
        read -r -p "Enter condition value: " condition_value

        # Find the index of the condition column
        condition_index=$(awk -F: -v colname="$condition_col" 'NR==1 {for (i=1; i<=NF; i++) if ($i == colname) print i}' $HOME/.Amrdb/$dbname/metadata_$tbname)
        if [[ -z $condition_index ]]; then
            echo "Error 0x0026: Column '$condition_col' not found."
            return
        fi

        # Prompt user for the column to update and the new value
        read -r -p "Enter column name to update: " update_col
        read -r -p "Enter new value: " new_value

        # Find the index of the column to update
        update_index=$(awk -F: -v colname="$update_col" 'NR==1 {for (i=1; i<=NF; i++) if ($i == colname) print i}' $HOME/.Amrdb/$dbname/metadata_$tbname)
        if [[ -z $update_index ]]; then
            echo "Error 0x0027: Column '$update_col' not found."
            return
        fi

        # Validate the new value against the column's data type
        coltype=${col_types[$((update_index - 1))]}
        if ! check_datatype "$coltype" "$new_value"; then
            return
        fi

        # Update rows that match the condition
        awk -F: -v condition_index="$condition_index" -v condition_value="$condition_value" -v update_index="$update_index" -v new_value="$new_value" '
        {
            if ($condition_index == condition_value) {
                $update_index = new_value
            }
            print
        }' OFS=: $HOME/.Amrdb/$dbname/$tbname > $HOME/.Amrdb/$dbname/temp_$tbname

        # Replace the original table with the updated one
        mv $HOME/.Amrdb/$dbname/temp_$tbname $HOME/.Amrdb/$dbname/$tbname

        echo "Table $tbname updated successfully."
    else
        echo "Error 0x0016 : 404 Table not found :)"
    fi
fi
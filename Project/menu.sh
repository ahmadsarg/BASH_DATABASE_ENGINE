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

function select_from_table() {
    read -r -p "Enter Table Name: " tbname
    tbname=$(echo $tbname | tr ' ' '_') # Replace any space with '_'
    check_table_name $tbname
    if (( $? == 0 )); then
        if [[ -f $HOME/.Amrdb/$dbname/$tbname ]]; then
            echo "1. Select all data"
            echo "2. Select specific column"
            echo "3. Select with WHERE condition"
            read -r -p "Enter your choice: " select_choice

            case $select_choice in
                1) # Select all data
                    echo "Contents of table $tbname:"
                    cat $HOME/.Amrdb/$dbname/$tbname
                    ;;
                2) # Select specific column
                    read -r -p "Enter column name: " colname
                    col_index=$(awk -F: -v colname="$colname" 'NR==1 {for (i=1; i<=NF; i++) if ($i == colname) print i}' $HOME/.Amrdb/$dbname/metadata_$tbname)
                    if [[ -z $col_index ]]; then
                        echo "Error 0x0024: Column '$colname' not found."
                    else
                        awk -F: -v col_index="$col_index" '{print $col_index}' $HOME/.Amrdb/$dbname/$tbname
                    fi
                    ;;
                3) # Select with WHERE condition
                    read -r -p "Enter column name for WHERE condition: " where_col
                    read -r -p "Enter value to match: " where_value
                    where_index=$(awk -F: -v where_col="$where_col" 'NR==1 {for (i=1; i<=NF; i++) if ($i == where_col) print i}' $HOME/.Amrdb/$dbname/metadata_$tbname)
                    if [[ -z $where_index ]]; then
                        echo "Error 0x0025: Column '$where_col' not found."
                    else
                        awk -F: -v where_index="$where_index" -v where_value="$where_value" '$where_index == where_value' $HOME/.Amrdb/$dbname/$tbname
                    fi
                    ;;
                *)
                    echo "Invalid choice. Please try again."
                    ;;
            esac
        else
            echo "Error 0x0016 : 404 Table not found :)"
        fi
    fi
}


function delete_table() {
    read -r -p "Enter Table Name: " tbname
    tbname=$(echo $tbname | tr ' ' '_') # Replace any space with '_'
    check_table_name $tbname
    if (( $? == 0 )); then
        if [[ -f $HOME/.Amrdb/$dbname/$tbname ]]; then
            echo "1. Delete all rows"
            echo "2. Delete rows with condition"
            read -r -p "Enter your choice: " delete_choice

            case $delete_choice in
                1) # Delete all rows
                    > $HOME/.Amrdb/$dbname/$tbname  # Clear the table file
                    echo "All rows deleted from table $tbname."
                    ;;
                2) # Delete rows with condition
                    read -r -p "Enter column name for condition: " colname
                    read -r -p "Enter value to match: " value
                    col_index=$(awk -F: -v colname="$colname" 'NR==1 {for (i=1; i<=NF; i++) if ($i == colname) print i}' $HOME/.Amrdb/$dbname/metadata_$tbname)
                    if [[ -z $col_index ]]; then
                        echo "Error 0x0026: Column '$colname' not found."
                    else
                        # Filter out rows that do not match the condition
                        awk -F: -v col_index="$col_index" -v value="$value" '$col_index != value' $HOME/.Amrdb/$dbname/$tbname > $HOME/.Amrdb/$dbname/temp_$tbname
                        mv $HOME/.Amrdb/$dbname/temp_$tbname $HOME/.Amrdb/$dbname/$tbname
                        echo "Rows where '$colname' equals '$value' deleted from table $tbname."
                    fi
                    ;;
                *)
                    echo "Invalid choice. Please try again."
                    ;;
            esac
        else
            echo "Error 0x0016 : 404 Table not found :)"
        fi
    fi
}

select choice in CreateTable InsertTable SelectTable DeleteTable UpdateTable "Exit"
do
    case $REPLY in
        1) # Create table
            source create_table.sh $dbname
            ;;
        2) # Insert into table
            source insert.sh $dbname
            ;;
        3) # Select table
            select_from_table
            ;;
        4) # Delete table
            delete_table
            ;;
        5) # Update table
            source update_table.sh $dbname
            ;;
        6) # Exit
            break
            ;;
        *)
            echo "Not a valid choice, please try again ..."
            ;;
    esac
done
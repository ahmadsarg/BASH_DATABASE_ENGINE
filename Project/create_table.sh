#! /usr/bin/bash
LC_COLLATE=C #To make the Terminal Case Senstive
shopt -s extglob #Enable Sub Pattern
export PS3="$1 >>"

function check_table_name(){
        
        if [[ $1 = [0-9]* ]] ; then 
            echo "Error 0x0006 : Table name can't start with a number."
            return 1
        else 
            case $1 in 
                    +([a-zA-Z_0-9])) 
                        return 0
                    ;;
                     *) 
                        echo "Error 0x0007 : Table name can't contain special characters."
                        return 1
                    ;;
            esac 
        fi
}


function check_col_name(){
        
        if [[ $1 = [0-9]* ]] ; then 
            echo "Error 0x0008 : Column name can't start with a number."
            return 1
        else 
            case $1 in 
                    +([a-zA-Z_0-9])) 
                        return 0
                    ;;
                     *) 
                        echo "Error 0x009 : Column name can't contain special characters."
                        return 1
                    ;;
            esac 
        fi
}



read -r -p "Enter Table Name : " tbname 
tbname=$(echo $tbname | tr ' ' '_') # Replace any space with '_'
check_table_name $tbname
if (( $? == 0 ));then
    if [[ -f $HOME/.Amrdb/$dbname/$tbname  ]];then
        echo "Error 0x0010 : Table already exists ..."
    else
        touch ./$tbname
        touch ./metadata_$tbname
        echo "Creating table ..."
        sleep 1
        #User enters digits only
        while true;do
            read -r -p "Enter Number of Fields: " num_col
            if [[ $num_col =~ ^[0-9]+$ ]];then
                break
            else
                echo "Error 0x0011: Enter a valid number ..."
            fi
        done
        col_names=()
        col_types=()
        for i in $(seq 1 "$num_col")
        do
            read -r -p "Enter Column Name(1st Col is PK): " colname 
            colname=$(echo $colname | tr ' ' '_') # Replace any space with '_'
            check_col_name $colname
            while (( $? == 1 ));do
                read -r -p "Enter Column Name(1st Col is PK): " colname 
                check_col_name $colname               
            done
            read -r -p "Enter Column Type: " coltype
            if (( $? == 0 ));then
                if grep -qw "$colname" "$HOME/.Amrdb/$dbname/metadata_$tbname" ;then
                    echo "Error 0x0012: Column already exists ..."
                else
                    if [[ "$coltype" == "int" || "$coltype" == "str" ]]; then
                        #read coltype here?
                        col_names+=("$colname")
                        col_types+=("$coltype")
                    else
                        while true;do
                            echo "Error 0x0013: Invalid column type. Please enter 'int' or 'str'."
                            read -r -p "Enter Column Type: " coltype
                            if [[ "$coltype" == "int" || "$coltype" == "str" ]]; then
                                col_names+=("$colname")
                                col_types+=("$coltype")
                                break
                            fi
                        done
                        
                    fi
                fi
            fi 
        done
        first_row=$(IFS=:; echo "${col_names[*]}")
        second_row=$(IFS=:; echo "${col_types[*]}")
        # sudo sed -i "1i $first_row" ./metadata_$tbname
        # sudo sed -i "2i $second_row" ./metadata_$tbname
        echo "$first_row" > ./metadata_$tbname
        echo "$second_row" >> ./metadata_$tbname
        echo "pk" >> ./metadata_$tbname
    fi      
fi






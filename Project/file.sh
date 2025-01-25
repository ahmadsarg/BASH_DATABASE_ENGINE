#! /usr/bin/bash
LC_COLLATE=C
shopt -s extglob
export PS3="Amrdb>>"


#Create DB Engine

function check_name_of_db(){
        
        if [[ $1 = [0-9]* ]] ; then 
            echo "Error 0x0001 : DB Name can't start with a number."
            return 1
        else 
            case $1 in 
                    +([a-zA-Z_0-9])) 
                        return 0
                    ;;
                     *) 
                        echo "Error 0x0002 : DB Name can't contain special characters."
                        return 1
                    ;;
            esac 
        fi
}



#Check DB Engine Name

if [[ -d $HOME/.Amrdb ]];then 
    echo "Engine already exists."
else
    mkdir $HOME/.Amrdb
    echo "Creating folder...."
    sleep 2
fi 


#Database Options

select choice in CreateDB ConnectDB ListDB RemoveDB "Exit"
do 
    case $REPLY in 
        1) #CreateDB
            read -r -p "Enter Database Name : " dbname 
            dbname=$(echo $dbname | tr ' ' '_') # Replace any space with '_'
            check_name_of_db $dbname
            if (( $? == 0 )) ; then 
                if [[ -d $HOME/.Amrdb/$dbname ]] ; then 
                    echo "Error 0x0003 : DB already exists ...."
                else  
                    mkdir $HOME/.Amrdb/$dbname
                    echo "Creating DB ....."
                    sleep 1
                    
                fi 
            fi 
        ;;
        2) #ConnectDB   
            read -r -p "Enter Database Name : " dbname   
            dbname=$(echo $dbname | tr ' ' '_') # Replace any space with '_'
            check_name_of_db $dbname
            if (( $? == 0 )) ; then 
                if [[ -d $HOME/.Amrdb/$dbname ]];then 
                    cd  $HOME/.Amrdb/$dbname 
                    echo "Entering $dbname database ..."
                    sleep 1
                    #source table_menu.sh $dbname   #Should be relative path
                    source menu.sh $dbname 
                else
                    echo "Error 0x0004 : 404 DB not found :) "
                fi
            fi
        ;;
        3) #ListDB

            #Ensure DB has folders only, no files.
            ls -F ~/.Amrdb/ | grep / | tr '/' ' ' #List all folders
        ;;
        4) #RemoveDB
            read -r -p "Enter Database Name : " dbname 
            dbname=$(echo $dbname | tr ' ' '_') # Replace any space with '_'
            check_name_of_db $dbname
            if (( $? == 0 )) ; then 
                if [[ -d $HOME/.Amrdb/$dbname ]];then 
                    rm -r $HOME/.Amrdb/$dbname
                    echo "Removing DB ......"
                    sleep 1
                else
                    echo "Error 0x0005 : 404 DB not found :) "
                fi 
            fi 
        ;;
        5) #Exit
            break
        ;;
        *)
            echo "Not a valid choice, please try again ..."
        ;;
    esac
done 
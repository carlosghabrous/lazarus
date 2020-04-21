#!/bin/bash

LAZARUS_DIR=".lazarus"

# FUNCTIONS
usage() {
    printf "%s\n" "Usage:"
    printf "\t%s\n" "lazarus <list|save|restore> [session_name]"
    exit 2
}


function list () {
    if [ ! -d "${HOME}/${LAZARUS_DIR}" ]; then 
        printf "%s\n" "Unable to list stored sessions: tmux directory $HOME/${LAZARUS_DIR} doesn't exist"
        exit 2
    fi

    printf "%s\n" "Available sessions..."
    for item in "${HOME}/${LAZARUS_DIR}/".*; do
        f="$(basename -- $item)"
        if [[ -f $item && $f = .lazarus* ]]; then
            IFS="_"
            read -ra ARR <<< "$f"
            printf "\t%s %s\n" "->" "${ARR[1]}"
            IFS=" "
        fi
    done 
}


function save() {
    printf "%s\n" "Saving session $1..."
    echo $1 >> "${HOME}/${LAZARUS_DIR}/${LAZARUS_SESSION_LIST_FILE}"
}


function restore() {
    echo "restore"
    echo $1
}


# MAIN
if [ $# -lt 1 ]; then
    printf "%s\n" "Missing command argument!"
    usage
fi 

case $1 in
    save | restore )
        if [ $# -lt 2 ]; then 
            printf "%s\n" "Missing session name"
            usage
        fi
        $1 $2
        ;;

    list )
        $1
        ;;

    * )
        printf "%s\n" "Unknown option"
        usage
        exit 2
esac



# lazarus list
# lazarus restore session_name
# lazarus save session_name
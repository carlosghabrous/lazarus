#!/bin/bash

LAZARUS_DIR=".lazarus"

# FUNCTIONS
function log() {
    printf "%s: %s\n" "$1" "$2"
}


function usage() {
    printf "%s\n" "Usage:"
    printf "\t%s\n" "lazarus <list|save|restore> [session_name]"
    exit 2
}


function list_existing_sessions() {
    log "INFO" "Existing sessions..."
    tmux ls
}


function session_exists() {
    tmux has-session -t=$1 2>/dev/null
}


function load_session() {
    printf "%s\n" "loading session $1"
    tmux start-server

}


function dump_session() {
    tmux list-windows -t $1
    tmux list-panes -s -t $1
}

function list () {
    if [ ! -d "${HOME}/${LAZARUS_DIR}" ]; then 
        log "ERROR" "Unable to list stored sessions: tmux directory $HOME/${LAZARUS_DIR} doesn't exist"
        exit 2
    fi

    log "INFO" "Stored sessions..."
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
    if ! session_exists $1; then
        log "ERROR" "Session $1 does not exist!"
        list_existing_sessions
        exit 2
    fi

    log "INFO" "Saving session $1..."
    dump_session $1 > "${HOME}/${LAZARUS_DIR}/.lazarus_$1"
}


function restore() {
    local found=0
    for item in "${HOME}/${LAZARUS_DIR}/".*; do
        f="$(basename -- $item)"
        if [[ -f $item && $f = .lazarus* ]]; then
            IFS="_"
            read -ra ARR <<< "$f"
            if [ $1 == "${ARR[1]}" ]; then
                found=1
                break
            fi
            IFS=" "
        fi
    done  

    if [ $found == 1 ]; then
        load_session $1
    else
        log "ERROR" "Session $1 not found!"
        list
        exit 2
    fi
}


# MAIN
if [ $# -lt 1 ]; then
    log "ERROR" "Missing command argument!"
    usage
fi 

case $1 in
    save | restore )
        if [ $# -lt 2 ]; then 
            log "ERROR" "Missing session name"
            usage
        fi
        $1 $2
        ;;

    list )
        $1
        ;;

    * )
        log "ERROR" "Unknown option"
        usage
        exit 2
esac



# lazarus list
# lazarus restore session_name
# lazarus save session_name
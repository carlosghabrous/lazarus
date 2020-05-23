#!/bin/bash
LAZARUS_DIR=${HOME}/".lazarus"

# FUNCTIONS
function log() {
    printf "%s: %s\n" "$1" "$2"
}


function usage() {
    printf "%s\n" "Usage:"
    printf "\t%s\n" "lazarus <list_current|list_stored|save|restore> [session_name]"
    exit 2
}


function list_existing_sessions() {
    log "INFO" "Existing sessions..."
    tmux ls
}


function session_exists() {
    tmux has-session -t=$1 2>/dev/null
}


function send_default_commands() {
    log "INFO" "Sending default commands"
}


function load_session() {
    if session_exists $1; then
        log "ERROR" "Session $1 already loaded! Exiting..."
        exit 2
    fi 

    printf "%s\n" "loading session $1"
    tmux start-server
    
    local session_created_already=0
    local current_window_name=""

    while IFS=$'\t' read session_name window_name window_layout pane_path; do
        if [ ${session_name} != $1 ]; then
            continue
        fi 

        # Found line with session to restore
        if [ ${session_created_already} == 0 ]; then
            log "INFO" "creating session $session_name"
            session_created_already=1

            log "INFO" "create window ${window_name}"
            tmux -2 new-session -d -s $1 -n ${window_name}
            current_window_name=${window_name}
        else
            if [[ ${current_window_name} == ${window_name} ]]; then
                log "INFO" "same window as before: ${window_name}"
            else
                log "INFO" "creating window ${window_name}"
                tmux new-window -n ${window_name} -a -t ${current_window_name}
                current_window_name=${window_name}
            fi
        fi 

    done < "${LAZARUS_DIR}/lazarus_$1"

    send_default_commands
    # tmux -2 attach -t ${session_name}
}


function dump_session() {
    local d=$'\t'
    tmux list-panes -s -t $1 -F "#S${d}#{window_name}${d}#{window_layout}${d}#{pane_current_path}#{client_activity}"
}


function list_current() {
    log "INFO" "Current sessions..."
    sessions=$(tmux list-sessions)
    IFS=$'\n'
    read -rd '' -a ARR <<< "$sessions"
    IFS=" "
    for i in "${ARR[@]}"
    do
        printf "\t%s %s\n" "->" "$i"
    done
}


function list_stored () {
    if [ ! -d "${LAZARUS_DIR}" ]; then 
        log "ERROR" "Unable to list stored sessions: tmux directory ${LAZARUS_DIR} doesn't exist"
        exit 2
    fi

    log "INFO" "Stored sessions..."
    for item in "${LAZARUS_DIR}/".*; do
        f="$(basename -- $item)"
        if [[ -f $item && $f = lazarus* ]]; then
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
        list_current
        exit 2
    fi

    log "INFO" "Saving session $1..."
    dump_session $1 > "${LAZARUS_DIR}/lazarus_$1"
}


function restore() {
    local found=0
    for item in "${LAZARUS_DIR}/"*; do
        f="$(basename -- $item)"
        if [[ -f $item && $f = lazarus* ]]; then
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
        list_stored
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

    list_stored | list_current)
        $1
        ;;

    * )
        log "ERROR" "Unknown option"
        usage
        exit 2
esac
# EOF
#!/bin/sh
# scan target and return service and port

usage() {
    echo "Tries to identify operating system using nmap"
    echo "USAGE:"
        echo "$0 <target>"
}
      
detect_os() {
    local detected="$(echo "$1" | grep "OS:" | awk -F 'OS: |Seq' '{print $2}')"
    if [ "$detected" ]; then
        echo "$detected"
    fi
}

# scan ports 1026-1027 for XBox 360 UPnP
is_xbox360() {
    xbox360string="XBox 360"
    local SCAN=$(nmap -sV -p 1026-1027 "$1")
    case "$SCAN" in
        *"$xbox360string"*)
            #echo "$xbox360string";;
            echo "xbox360";;
    esac
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit
    else
        RESULT="{ "

        [ ! -p /tmp/fifo ] && mkfifo /tmp/fifo
        nmap -O --osscan-guess --fuzzy $1 > /tmp/fifo &
        while read -r line
        do
            case "$line" in
                *"open"*)
                    SERVICE=$(echo "$line" | awk '{print $3}')
                    if [ $SERVICE == "LSA-or-nterm" ]; then
                        SERVICE=$(is_xbox360 "$1")
                    fi

                    PORT=$(echo "$line" | awk -F "/" '{print $1}')
                    # if port is a number
                    if [ "$PORT" -eq "$PORT" ] 2>/dev/null; then
                        RESULT="$RESULT\"$SERVICE\": $PORT, "
                    fi
                ;;
            esac
        done < /tmp/fifo
        rm /tmp/fifo

        # return string if we found anything
        NOT_FOUND_MSG="Couldn't find any open services"
        echo "$RESULT" | sed 's/, $/ }/' | sed 's/{ $/Could not find any open services/'
    fi
}

main $1

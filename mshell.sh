#!/bin/bash
#global shared proxy and miners config
source mshell.cfg

function startproxy {
    echo "Starting the proxy [$PROXYCOMMAND]"
    PROXYLOG=$LOGSDIR/proxy.log
    $PROXYCOMMAND &> $PROXYLOG &
    PROXYPID=$!
}

function stopproxy {
    if [ -n $PROXYPID ]
    then
        echo "Shutting down the proxy"
        kill $PROXYPID
    else
        echo "The proxy is not running!"
    fi
}

function startminer {
    #starts the miner, saves its log into a file, renices it and stores its PID and given name for further usage
    NAME=$1
    COMMAND=$2
    echo "starting $NAME miner"
    $COMMAND &> "$LOGSDIR/$NAME.miner.log" &
    #renice so you can still use the system :)
    renice 19 -p $! &> /dev/null
    RUNNINGMINERS["$NAME"]=$!
}

function stopminer {
    RUNNINGMINER=$1
    echo "Shutting down miner $RUNNINGMINER"
    kill ${RUNNINGMINERS["$RUNNINGMINER"]}
}

function quit {
    if [ -n $PROXYPID ]
    then
        stopproxy
    fi
    for RUNNINGMINER in "${!RUNNINGMINERS[@]}"
    do
        stopminer $RUNNINGMINER
    done
    echo "Finished!"
    exit
}

function print_help {
    echo "Available commands: "
    echo "h | help: print the help"
    echo "s | status: show the proxy and miner status"
    echo "c | clear: clear screen"
    echo "q | quit: shut down the proxy and the miner and exit"
}

function show_status {
    #print the PID and last lines of the log file for the proxy and each running miner
    if [ -n $PROXYPID ]
    then
        echo "------------------------"
        echo "[$PROXYPID] PROXY STATUS"
        echo "------------------------"
        tail $PROXYLOG
        echo ""
    fi
    for RUNNINGMINER in "${!RUNNINGMINERS[@]}"
    do
        echo "------------------------"
        echo "[${RUNNINGMINERS["$RUNNINGMINER"]}] $RUNNINGMINER"
        echo "------------------------"
        tail $LOGSDIR/$RUNNINGMINER.miner.log
        echo ""
    done
}


echo "Cleaning up previous logs"
rm -f $LOGSDIR/*

#start the proxy if needed
if [ $STARTPROXY -ne 0 ]
then
    startproxy
fi

#start the miners that are configured to autostart
#NOTE THAT MULTIPLE MINERS CAN RUN WITH THE SAME PROXY
MINERRE='"(.+)"\s+([01])\s+"(.+)"'
COMMENTRE='#.*'
declare -A RUNNINGMINERS
declare -A CONFIGUREDMINERS
while read LINE
do
    if [[ $LINE =~ $MINERRE ]]
    then
        NAME=${BASH_REMATCH[1]}
        AUTOSTART=${BASH_REMATCH[2]}
        #using the eval to expand the variables
        COMMAND=$(eval echo ${BASH_REMATCH[3]})
        echo "registering miner $NAME [$COMMAND]"
        #store it for further usage
        CONFIGUREDMINERS["$NAME"]=$COMMAND
        if [ $AUTOSTART -eq 1 ]
        then
            startminer "$NAME" "$COMMAND"
        fi
    fi
    if [[ ! $LINE =~ $COMENTRE ]]
    then
        echo "unrecognized miners.cfg line:"
        echo $LINE
    fi
done < miners.cfg

#kill the workers and the proxy when this script is killed or interrupted
trap quit SIGHUP SIGINT SIGTERM

#simple shell
while [ 1 ]
do
    read -p "mshell $ "

    case $REPLY in
    "h" | "help")
        print_help
        ;;
    "s" | "status")
        show_status
        ;;
    "c" | "clear")
        clear
        ;;
    "q" | "quit")
        quit
        ;;
    *)
        print_help
        ;;
    esac
done

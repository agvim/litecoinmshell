#!/bin/bash
#global shared proxy and miners config
source mshell.cfg

function startproxy {
    if [[ -n $PROXYPID ]]
    then
        echo "The proxy is already running"
        return 1
    else
        echo "Starting the proxy [$PROXYCOMMAND]"
        PROXYLOG=$LOGSDIR/proxy.log
        $PROXYCOMMAND &> $PROXYLOG &
        PROXYPID=$!
    fi
}

function stopproxy {
    if [ -n $PROXYPID ]
    then
        echo "Shutting down the proxy"
        kill $PROXYPID &> /dev/null
        unset PROXYPID
    else
        echo "The proxy is not running!"
        return 1
    fi
}

function startminer {
    #starts the miner, saves its log into a file, renices it and stores its PID and given name for further usage
    NAME=$1
    if [[ ${RUNNINGMINERS[$NAME]} != "" ]]
    then
        echo "a miner with that name is already running"
        return 1
    fi
    #if there are two arguments the second is the command to run for that name
    if [[ $# -ge 2 ]]
    then
        shift
        echo "$*"
        CONFIGUREDMINERS[$NAME]=$*
    fi
    COMMAND=${CONFIGUREDMINERS[$NAME]}
    if [[ $COMMAND == "" ]]
    then
        echo "unrecognized miner name"
        return 1
    fi
    echo "starting $NAME miner [$COMMAND]"
    $COMMAND &> "$LOGSDIR/$NAME.miner.log" &
    #renice so you can still use the system :)
    renice 19 -p $! &> /dev/null
    RUNNINGMINERS["$NAME"]=$!
}

function stopminer {
    RUNNINGMINER=$1
    if [[ ${RUNNINGMINERS[$RUNNINGMINER]} == "" ]]
    then
        echo "unrecognized miner name"
        return 1
    fi
    echo "Shutting down miner $RUNNINGMINER"
    kill ${RUNNINGMINERS[$RUNNINGMINER]} &> /dev/null
    #deregister it from the running list
    unset RUNNINGMINERS[$RUNNINGMINER]
}

function quit {
    if [ -n $PROXYPID ]
    then
        stopproxy
    fi
    for RUNNINGMINER in ${!RUNNINGMINERS[@]}
    do
        stopminer $RUNNINGMINER
    done
    echo "Finished!"
    exit
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
    for RUNNINGMINER in ${!RUNNINGMINERS[@]}
    do
        echo "------------------------"
        echo "[${RUNNINGMINERS[$RUNNINGMINER]}] $RUNNINGMINER"
        echo "------------------------"
        tail $LOGSDIR/$RUNNINGMINER.miner.log
        echo ""
    done
}

function list {
    #print the list of registered miners with its commands and the running ones
    echo "REGISTERD MINERS:"
    for REGISTEREDMINER in ${!CONFIGUREDMINERS[@]}
    do
        echo "  $REGISTEREDMINER [${CONFIGUREDMINERS[$REGISTEREDMINER]}]"
    done
    echo "RUNNING MINERS:"
    for RUNNINGMINER in ${!RUNNINGMINERS[@]}
    do
        echo "  $RUNNINGMINER"
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
        CONFIGUREDMINERS[$NAME]=$COMMAND
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

function print_help {
    echo "Available commands: "
    echo "h | help: print the help"
    echo "t | status: show the proxy and miner status"
    echo "c | clear: clear screen"
    echo "q | quit: shut down the proxy and the miner and exit"
    echo "l | list: list the registered and active miners"
    echo "k | kill <minername>: stops the <minername> miner"
    echo "s | start <minername> [command]: starts the <minername> miner. If command is specified the miner is registered with <minername> and started with [command]"
    echo "kp | killproxy: stops the proxy"
    echo "sp | startproxy: starts the proxy"
}

#simple shell
while [ 1 ]
do
    read -p "mshell $ "
    COMMAND=`echo $REPLY | cut -d ' ' -f 1`
    ARGS=`echo $REPLY | cut -s -d ' ' -f 2-`
    case $COMMAND in
    "h" | "help")
        print_help
        ;;
    "t" | "status")
        if [[ $ARGS != "" ]]
        then
            print_help
        else
            show_status
        fi
        ;;
    "c" | "clear")
        if [[ $ARGS != "" ]]
        then
            print_help
        else
            clear
        fi
        ;;
    "q" | "quit")
        if [[ $ARGS != "" ]]
        then
            print_help
        else
            quit
        fi
        ;;
    "l" | "list")
        if [[ $ARGS != "" ]]
        then
            print_help
        else
            list
        fi
        ;;
    "k" | "kill")
        if [[ $ARGS != "" ]]
        then
            stopminer $ARGS
        else
            print_help
        fi
        ;;
    "s" | "start")
        if [[ $ARGS != "" ]]
        then
            startminer $ARGS
        else
            print_help
        fi
        ;;
    "kp" | "killproxy")
        if [[ $ARGS != "" ]]
        then
            print_help
        else
            stopproxy
        fi
        ;;
    "sp" | "startproxy")
        if [[ $ARGS != "" ]]
        then
            print_help
        else
            startproxy
        fi
        ;;
    *)
        print_help
        ;;
    esac
done

[[ $EUID != 0 ]] && echo "run as root" && exit 1                                                                # ensure run by root

if [ "$1" ]                                                                                                     # ensure parameter provided
then
    if [ "$1" = "start" ]
        then
            echo "starting..."                                                               #
            echo "type \"exit\" after the process starts"                                                       #
            echo "check nohup.out for logs"                                                                     #
            sudo nohup ./macsvc &                                                                               # start macsvc
        elif [ "$1" = "stop" ]
        then
            echo "stopping..."
            macsvc=$(pidof macsvc)                                                                              # get pid of macsvc
            if [ "$macsvc" ]
                then
                    sudo kill $macsvc                                                                           # kill if exists
                    echo "killed macsvc (macsvc $macsvc)"                                                       # success message
                else
                    echo "macsvc proces not found"                                                              # process not found
            fi
        else
            echo "please provide a parameter, start or stop"                                                    # invalid parameter
    fi
else
    echo "please provide a parameter, start or stop"                                                             # no parameter
fi
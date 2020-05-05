#!/bin/bash

if [ $# == 0 ]; then 
    echo "Usage: $0 SLACK_WEBHOOK_URL"
    exit 1
fi

HOSTNAME=`hostname`
NGROK_URL=`curl -s localhost:4040/api/tunnels | jq -r .tunnels[].public_url | grep --color=never https://*`
SLACK_WEBHOOK_URL=$1

if [ "$NGROK_URL" != "" ]; then
    TEXT="[$HOSTNAME]\n$NGROK_URL"
    curl -s -X POST -H 'Content-type: application/json' --data '{"text":"'"$TEXT"'"}' $SLACK_WEBHOOK_URL > /dev/null
    PREV_NGROK_URL=$NGROK_URL
else
    PREV_NGROK_URL=""
fi

while :
do
    NGROK_URL=`curl -s localhost:4040/api/tunnels | jq -r .tunnels[].public_url | grep --color=never https://*`
    if [ "$NGROK_URL" != "$PREV_NGROK_URL" ]; then
        if [ "$NGROK_URL" = "" ]; then
            TEXT="[$HOSTNAME] connecting"
            curl -s -X POST -H 'Content-type: application/json' --data '{"text":"'"$TEXT"'"}' $SLACK_WEBHOOK_URL > /dev/null
        else
            if [ "$PREV_NGROK_URL" != ""]; then
                TEXT="[$HOSTNAME] disconnect"
                curl -s -X POST -H 'Content-type: application/json' --data '{"text":"'"$TEXT"'"}' $SLACK_WEBHOOK_URL > /dev/null
            fi
        fi

        while [ "$NGROK_URL" = "" ]
        do
            NGROK_URL=`curl -s localhost:4040/api/tunnels | jq -r .tunnels[].public_url | grep --color=never https://*`
            sleep 1
        done

        TEXT="[$HOSTNAME]\n$NGROK_URL"
        curl -s -X POST -H 'Content-type: application/json' --data '{"text":"'"$TEXT"'"}' $SLACK_WEBHOOK_URL > /dev/null
        PREV_NGROK_URL=$NGROK_URL
    fi

    sleep 1

done

exit 0

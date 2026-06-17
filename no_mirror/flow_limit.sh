#!/bin/bash

. ./flow_include.sh

countall

#optional... look for posting processes to still be running?

function wait_retry {

stalled=0
stalled_value=-1
retry_msgcnt="`cat "$CACHEDIR"/*/*_f[0-9][0-9]/*retry* 2>/dev/null | sort -u | wc -l`"
while [ $retry_msgcnt -gt 0 ]; do
        printf "Still %4s messages to retry, waiting...\n" "$retry_msgcnt"
        sleep 10
        retry_msgcnt="`cat "$CACHEDIR"/*/*_f[0-9][0-9]/*retry* 2> /dev/null | sort -u | wc -l`"

        if [ "${stalled_value}" == "${retry_msgcnt}" ]; then
              stalled=$((stalled+1));
              if [ "${stalled}" == 5 ]; then
                 printf "\n    Warning some retries stalled, skipping..., might want to check the logs\n\n"
                 retry_msgcnt=0
              fi
        else
              stalled_value=$retry_msgcnt
              stalled=0
        fi

done

}

#queued_msgcnt="`rabbitmqadmin -H localhost -u bunnymaster -p ${adminpw} -f tsv list queues | awk ' BEGIN {t=0;} (NR > 1)  && /_f[0-9][0-9]/ { t+=$(23); }; END { print t; };'`"
queued_msgcnt="`rabbitmqadmin -H localhost -u bunnymaster -p ${adminpw} -f tsv list queues | awk ' BEGIN {t=0;} (NR > 1)  && /_f[0-9][0-9]/ { t+=$2; }; END { print t; };'`"
while [ $queued_msgcnt -gt 0 ]; do
        queues_with_msgs="`rabbitmqadmin -H localhost -u bunnymaster -p ${adminpw} -f tsv list queues | awk ' BEGIN {t=0;} (NR > 1)  && /_f[0-9][0-9]/ && ( $2 > 0 ) { print $1; };' | sed ':a;N;$!ba;s/\\n/, /g' `"
        printf "${flow_test_name} Still %4s messages (in queues: %s) flowing, waiting...\n" "$queued_msgcnt" "$queues_with_msgs"
        sleep 10
        queued_msgcnt="`rabbitmqadmin -H localhost -u bunnymaster -p ${adminpw} -f tsv list queues | awk ' BEGIN {t=0;} (NR > 1)  && /_f[0-9][0-9]/ { t+=$2; }; END { print t; };'`"

        wait_retry
done

sleepytime=300
printf "\nwaiting $sleepytime for things to settle out\n"
sleep $sleepytime

date +'%s' >"${LOGDIR}/timestamp_end.txt"



printf "\n\nflow test ${flow_test_name} stopped. \n\n"


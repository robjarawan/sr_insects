#!/bin/bash

# make sure libsrshim is off

# if running local sarra/sarrac versions, specify path to them with 
# $SARRA_LIB and $SARRAC_LIB, and $SR_POST_CONFIG 
# contains the path to shim_f63.conf (usually in $CONFDIR/cpost/
# shimpost.conf, but specify if otherwise)
# defaults:
#export SR_POST_CONFIG="$CONFDIR/post/shim_f63.conf"
#export SARRA_LIB=""
#export SARRAC_LIB=""


#  argument could be: config, declare or nothing.
#  if nothing, do the whole thing.

#export PYTHONPATH="`pwd`/../"
. ../flow_utils.sh

echo "FIXME sarra_py_version=${sarra_py_version}"
export sarra_py_version=${sarra_py_version}

testdocroot="$HOME/sarra_devdocroot"
testhost=localhost
sftpuser=`whoami`
flowsetuplog="$LOGDIR/flowsetup_f00.log"


if [ -d $LOGDIR ]; then
    logs2remove=$(find "$LOGDIR" -iname "*.txt" -o -iname "*f[0-9][0-9]*.log")
    if [ ! -z "$logs2remove" ]; then
       echo "Cleaning previous flow test logs..."
       rm $logs2remove
    fi
fi

date +'%s' >"${LOGDIR}/timestamp_start.txt"

if [ ! -d "$testdocroot" ]; then
  mkdir $testdocroot
  cp -r testree/* $testdocroot
  mkdir $testdocroot/bulletins_to_download
  mkdir $testdocroot/bulletins_to_post
fi

lo="`netstat -an | grep '127.0.0.1:8001'|wc -l`"
while [ ${lo} -gt 0 ]; do
   echo "Waiting for $lo leftover sockets to clean themselves up from last run."
   sleep 10 
   lo="`netstat -an | grep '127.0.0.1:8001'|wc -l`"
   sleep 5 
done

mkdir -p "$CONFDIR" 2> /dev/null
mkdir -p "$HOME/.config/sarra" 2> /dev/null

#flow_configs="`cd ${SR_CONFIG_EXAMPLES}; ls */*f[0-9][0-9].conf; ls */*f[0-9][0-9].inc`"
flow_configs="`cd ${SR_TEST_CONFIGS}; ls */*.inc; ls */*.conf;`"

if [ "${sarra_py_version:0:1}" == "3" ]; then
    cd ${SR_TEST_CONFIGS} ; cp -r *  ${HOME}/.config/sr3
    cd ..
fi

######## No need to convert the configs. They are already in v3. ########
# echo "Adding AM flow test configurations..."
if [ "$1" != "skipconfig" ]; then 
#   cd ${SR_TEST_CONFIGS} ; cp -r *  ${HOME}/.config/sarra
#   cd ..
#   if [ "${sarra_py_version:0:1}" == "3" ]; then
#     if [  "${sarra_py_version:5:2}" -ge "54" ]; then
#        sr3 convert ${flow_configs}
#     else
#        for i in ${flow_configs}; do
#            sr3 convert $i
#        done
#     fi
#   fi

   if [ "$1" == "config" ]; then
       exit 0
   fi
fi

passed_checks=0
count_of_checks=0

# ensure users have exchanges:

echo "Initializing with sr_audit... takes a minute or two"
if [ "${sarra_py_version:0:1}" == "3" ]; then
    sr_action --users declare
else
    if [ ! "$SARRA_LIB" ]; then
        sr_audit -debug -users foreground >>$flowsetuplog 2>&1
    else
        "$SARRA_LIB"/sr_audit.py -debug -users foreground >>$flowsetuplog 2>&1
    fi
fi

# Check queues and exchanges
qchk 3 "queues existing after 1st audit"
xchk "exchanges for flow test created"

if [ "$1" = "declare" ]; then
   exit 0
fi

testrundir="`pwd`"

echo "Starting trivial upstream http server on: ${SAMPLEDATA}, saving pid in .upstreamhttpserverpid"
cd ${SAMPLEDATA}
$testrundir/../trivialserver.py 8090 >>$trivialupstreamhttplog   2>&1 &
upstreamhttpserverpid=$!

echo "Starting trivial downstream http server on: $testdocroot, saving pid in .httpserverpid"
cd $testdocroot
$testrundir/../trivialserver.py >>$trivialhttplog 2>&1 &
httpserverpid=$!


echo "Starting trivial ftp server on: $testdocroot, saving pid in .ftpserverpid"

nbr_test=0
nbr_fail=0

if [ "$1" = "ready" ]; then
   exit 0
fi

cd $testrundir

echo ${upstreamhttpserverpid} >.upstreamhttpserverpid
echo $httpserverpid >.httpserverpid
echo $testdocroot >.httpdocroot
echo $flowpostpid >.flowpostpid

if [ ${#} -ge 1 ]; then
export MAX_MESSAGES=${1}
echo $MAX_MESSAGES
fi

echo "sr starting "
if [ "${sarra_py_version:0:1}" == "3" ]; then
   sr3 start
   ret=$?
else
   sr start
   ret=$?
fi

count_of_checks=$((${count_of_checks}+1))
if [ $ret -ne 0 ]; then
   echo "FAILED: sr start returned error status"
else
   echo "OK: sr start was successful"
   passed_checks=$((${passed_checks}+1))
fi

abit=20
echo "waiting a bit $abit to let processing get started..."
sleep $abit

# For the watch. To notice the new files after it's been started.
cp -r ${SAMPLEDATA}/20200105/WXO-DD/bulletins/alphanumeric/* $testdocroot/bulletins_to_post/bulletins/


if [ $passed_checks = $count_of_checks ]; then
   echo "Overall ${flow_test_name}: PASSED $passed_checks/$count_of_checks checks passed!"
else
   echo "Overall ${flow_test_name}: FAILED $passed_checks/$count_of_checks passed."
fi


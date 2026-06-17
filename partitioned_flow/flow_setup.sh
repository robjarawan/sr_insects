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
  mkdir $testdocroot/downloaded_by_sub_amqp
  mkdir $testdocroot/downloaded_by_sub_u
  mkdir $testdocroot/sent_by_tsource2send
  mkdir $testdocroot/recd_by_srpoll_test1
  mkdir $testdocroot/posted_by_srpost_test2
  mkdir $testdocroot/posted_by_shim
  mkdir $testdocroot/cfr
  mkdir $testdocroot/cfile
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
flow_configs="`cd ${SR_TEST_CONFIGS}; ls */*f[0-9][0-9].inc; ls */*f[0-9][0-9].conf;`"

echo "Adding static flow test configurations..."
if [ "$1" != "skipconfig" ]; then 
   cd ${SR_TEST_CONFIGS} ; cp -r *  ${HOME}/.config/sarra
   cd ..
   if [ "${sarra_py_version:0:1}" == "3" ]; then
      if [  "${sarra_py_version:5:2}" -ge "54" -o "${sarra_py_version:2:2}" -gt "00" ]; then
          sr3 convert ${flow_configs}
      else
          for i in ${flow_configs}; do
              sr3 convert $i
          done
      fi
      for c in ${flow_configs}; do
          echo rm ${HOME}/.config/sarra/${c}
          rm ${HOME}/.config/sarra/${c}
      done
   fi

   if [ "$1" == "config" ]; then
       exit 0
   fi
fi

passed_checks=0
count_of_checks=0

#xchk 8 "only rabbitmq default systems exchanges should be present."

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
qchk 15 "queues existing after 1st audit"
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

# note, on older OS, pyftpdlib might need to be installed as a python2 extension.
# 
# note, defaults to port 2121 so devs can start it.

if [ "`lsb_release -rs`" = "14.04"  ]; then
   python -m pyftpdlib >>$trivialftplog 2>&1 &
else
   python3 -m pyftpdlib >>$trivialftplog 2>&1 &
fi
ftpserverpid=$!

sleep 3

if [ ! "`head $trivialftplog | grep 'starting'`" ]; then
   echo "FAILED to start FTP server, is pyftpdlib installed?"
else
   echo "FTP server started." 
   passed_checks=$((${passed_checks}+1))
fi
count_of_checks=$((${count_of_checks}+1))

nbr_test=0
nbr_fail=0

if [ "$1" = "ready" ]; then
   exit 0
fi

cd $testrundir

echo $ftpserverpid >.ftpserverpid
echo ${upstreamhttpserverpid} >.upstreamhttpserverpid
echo $httpserverpid >.httpserverpid
echo $testdocroot >.httpdocroot
echo $flowpostpid >.flowpostpid

if [ ${#} -ge 1 ]; then
export MAX_MESSAGES=${1}
echo $MAX_MESSAGES
fi

echo "starting to post: `date +${SR_DATE_FMT}`"
if [ "${sarra_py_version:0:1}" == "3" ]; then
   POST=sr3_post
   CPOST=sr3_cpost
   LGPFX=''
else
   POST=sr_post
   CPOST=sr_cpost
   LGPFX='sr_'
fi
export POST CPOST LGPFX

echo "Starting flow_post on: $testdocroot, saving pid in .flowpostpid"
./flow_post.sh >$srposterlog 2>&1 &
flowpostpid=$!

if [ ! "$SARRA_LIB" ]; then
    bash -c '$POST -c t_dd1_f00.conf ${SAMPLEDATA}' >$LOGDIR/post_t_dd1_f00_01.log 2>&1 &
    bash -c '$POST -c t_dd2_f00.conf ${SAMPLEDATA}' >$LOGDIR/post_t_dd2_f00_01.log 2>&1 &
else
    "$SARRA_LIB"/sr_post.py -c t_dd1_f00.conf ${SAMPLEDATA} >$LOGDIR/post_t_dd1_f00_01.log 2>&1 &
    "$SARRA_LIB"/sr_post.py -c t_dd2_f00.conf ${SAMPLEDATA} >$LOGDIR/post_t_dd2_f00_01.log 2>&1 &
fi

$CPOST -c pelle_dd1_f04.conf >$LOGDIR/cpost_pelle_dd1_f04_01.log 2>&1 &
$CPOST -c pelle_dd2_f05.conf >$LOGDIR/cpost_pelle_dd2_f05_01.log 2>&1 &

echo "posting complete: `date +${SR_DATE_FMT}`"

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

if [ $passed_checks = $count_of_checks ]; then
   echo "Overall ${flow_test_name}: PASSED $passed_checks/$count_of_checks checks passed!"
else
   echo "Overall ${flow_test_name}: FAILED $passed_checks/$count_of_checks passed."
fi


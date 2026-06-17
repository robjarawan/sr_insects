#!/bin/bash

. ../flow_utils.sh

C_ALSO="`which sr_cpost`"

if [ ! "${C_ALSO}" ]; then
   C_ALSO="`which sr3_cpost`"
fi

# The directory we run the flow test scripts in...
tstdir="`pwd`"
httpdocroot=`cat $tstdir/.httpdocroot`
testdocroot="$HOME/sarra_devdocroot"

function countthem {
   if [ ! "${1}" ]; then
      tot=0
   else
      tot="${1}"
   fi
}

function chkargs {

   if [[ ! "${1}" || ! "${2}" ]]; then
      printf "test %2d FAILURE: blank results! ${3}\n" ${tno}
      return 2
   fi
   if [[ "${1}" -eq 0 ]]; then
      printf "test %2d FAILURE: no successful results! ${3}\n" ${tno}
      return 2
   fi

   if [[ "${2}" -eq 0 ]]; then
      printf "test %2d FAILURE: no successful results, 2nd item! ${3}\n" ${tno}
      return 2
   fi

   return 0
}

function calcres {
   #
   # calcres - Calculate test result.
   # 
   # logic:
   # increment test number (tno)
   # compare first and second totals, and report agreement if within 10% of one another.
   # emit description based on agreement.  Arguments:
   # 1 - first total
   # 2 - second total 
   # 3 - test description string.
   # 4 - will retry flag.
   #
   
   tno=$((${tno}+1))

   chkargs "${1}" "${2}" "${3}"
   if [ $? -ne 0 ]; then
      return $?
   fi

   res=0

   mean=$(( (${1} + ${2}) / 2 ))
   maxerr=$(( $mean / 10 ))

   min=$(( $mean - $maxerr ))
   max=$(( $mean + $maxerr ))

   if [ $1 -lt $min -o $2 -lt $min -o $1 -gt $max -o $1 -gt $max ]; then
	   printf "test %2d FAILURE: ${3}\n" ${tno}
      if [ "$4" ]; then
         tno=$((${tno}-1))
      fi    
      return 1
   else
      printf "test %2d success: ${3}\n" ${tno}
      passedno=$((${passedno}+1))
      return 0
   fi

}

function tallyres {
   # tallyres - All the results must be good.  99/100 is bad!
   # 
   # logic:
   # increment test number (tno)
   # compare first and second totals, and report agreement of one another.
   # emit description based on agreement.  Arguments:
   # 1 - value obtained 
   # 2 - value expected
   # 3 - test description string.

   tno=$((${tno}+1))

   if [ ${1} -ne ${2} -o ${2} -eq 0 ]; then
      printf "test %2d FAILURE: ${3}\n" ${tno}
      if [ "$4" ]; then
         tno=$((${tno}-1))
      fi    
      return 1
   else
      printf "test %2d success: ${3}\n" ${tno}
      passedno=$((${passedno}+1))
      return 0
   fi

}

function zerowanted {
   # zerowanted - this value must be zero... checking for bad things.
   # 
   # logic:
   # increment test number (tno)
   # compare first and second totals, and report agreement if within 10% of one another.
   # emit description based on agreement.  Arguments:
   # 1 - value obtained 
   # 2 - samplesize
   # 3 - test description string.

   tno=$((${tno}+1))

   if [ "${2}" -eq 0 ]; then
      printf "test %2d FAILURE: no data! ${3}\n" ${tno}
      return
   fi

   if [ "${1}" -gt 0 ]; then
      printf "test %2d FAILURE: ${1} ${3}\n" ${tno}
   else
      printf "test %2d success: ${1} ${3}\n" ${tno}
      passedno=$((${passedno}+1))
   fi
}

function sumlogs {

  pat="$1"
  shift
  tot=0
  for l in $*; do
     to_add="`grep "\[INFO\] $pat" $l | tail -1 | awk ' { print $5; }; '`"
     if [ "$to_add" ]; then
        tot=$((${tot}+${to_add}))
     fi
  done
}

function sumlogshistory {
  p="$1"
  shift
  if [[ $(ls $* 2>/dev/null) ]]; then
      reverse_date_logs=`ls $* | sort -n -r`

      for l in $reverse_date_logs; do
         if [[ ${tot} = 0 ]]; then
             sumlogs $p $l
         fi
      done
  fi
}

function countall {

  sumlogs msg_total $LOGDIR/${LGPFX}report_tsarra_f20_*.log
  totsarra="${tot}"

  if [ "${sarra_py_version:0:1}" == "3" ]; then
       countthem "`grep -a 'log after_post posted' "$LOGDIR"/${LGPFX}post_t_dd1_f00_*.log | wc -l`"
  else
       countthem "`grep -a '\[INFO\] post_log' "$LOGDIR"/${LGPFX}post_t_dd1_f00_*.log | wc -l`"
  fi
  totshovel1="${tot}"

  if [ "${sarra_py_version:0:1}" == "3" ]; then
       countthem "`grep -a 'log after_post posted' "$LOGDIR"/${LGPFX}post_t_dd2_f00_*.log | wc -l`"
       totshovel2="${tot}"
       countthem "`grep -a 'rejected:.*404.*mask=' "$LOGDIR"/${LGPFX}post_t_dd2_f00_*.log | wc -l`"
       totshovel2rej="${tot}"
       countthem "`grep -a 'rejected:.*304.*Not modified' "$LOGDIR"/${LGPFX}sarra_download_f20_*.log | wc -l`"
       totwinnowed="${tot}"
  else
       countthem "`grep -a '\[INFO\] post_log' "$LOGDIR"/${LGPFX}post_t_dd2_f00_*.log | wc -l`"
       totshovel2="${tot}"
       countthem "`grep -a 'reject: mask=' "$LOGDIR"/${LGPFX}post_t_dd2_f00_*.log | wc -l`"
       totshovel2rej="${tot}"
       countthem "`grep rejected  "$LOGDIR"/${LGPFX}sarra_download_f20_*.log | grep -v DEBUG | wc -l`"
       totwinnowed="${tot}"
  fi


  if [ "${sarra_py_version:0:1}" == "3" ]; then
       countthem "`grep 'log after_post posted' "$LOGDIR"/${LGPFX}watch_f40_*.log | grep -v directory | wc -l`"
  else
       countthem "`grep '\[INFO\] post_log' "$LOGDIR"/${LGPFX}watch_f40_*.log | wc -l`"
  fi
  totfilewatch="${tot}"


  if [[ "${sarra_py_version}" > "3.00.52" ]]; then
      countthem "`grep 'after_post posted .* a directory' "$LOGDIR"/${LGPFX}watch_f40_*.log | wc -l`"
      totdirwatch="${tot}"

      countthem "`sr3 status | grep -a 'wVip' | wc -l `"
      totwvip="${tot}"

  elif [[ "${sarra_py_version}" > "3.00.25" ]]; then
      countthem "`grep 'after_work directory ok' "$LOGDIR"/${LGPFX}watch_f40_*.log | awk ' { print $8; } ' | sort -u  | wc -l`"
      totdirwatch="${tot}"
  else
      totdirwatch=0
  fi

  totwatch=$((${totfilewatch}+${totdirwatch}))



  sumlogs msg_total $LOGDIR/${LGPFX}subscribe_amqp_f30_*.log
  totmsgamqp="${tot}"

  if [ "${sarra_py_version:0:1}" == "3" ]; then
	  countthem "`grep -aE 'after_work (directory|downloaded) ok:' "$LOGDIR"/${LGPFX}subscribe_amqp_f30_*.log | wc -l`"
  else
      countthem "`grep -a '\[INFO\] file_log downloaded to:' "$LOGDIR"/${LGPFX}subscribe_amqp_f30_*.log | wc -l`"
  fi
  totfileamqp="${tot}"


  if [[ "${sarra_py_version}" > "3.00.25" ]]; then
      countthem "`grep -a 'log after_post posted' "$LOGDIR"/${LGPFX}sender_tsource2send_f50_*.log | grep directory | wc -l`"
      totdirsent="${tot}"
      countthem "`grep -a 'log after_post posted' "$LOGDIR"/${LGPFX}sender_tsource2send_f50_*.log | grep \'m, | wc -l`"
      totdirsent="$((${tot}+${totdirsent}))"
  else
       totdirsent=0
  fi


  if [ "${sarra_py_version:0:1}" == "3" ]; then
      countthem "`grep -a 'log after_post posted' "$LOGDIR"/${LGPFX}sender_tsource2send_f50_*.log | grep -v directory | grep -v \'m, | wc -l`"
  else
      countthem "`grep -a '\[INFO\] post_log notice' "$LOGDIR"/${LGPFX}sender_tsource2send_f50_*.log | wc -l`"
  fi
  totfilesent="${tot}"
  totsent=$((${totfilesent}+${totdirsent}))

  if [ "${sarra_py_version:0:1}" == "3" ]; then
      all_events="directory ok:|downloaded ok:|filtered ok:|written from message ok:"
      countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_rabbitmqtt_f31_*.log | grep -v DEBUG | wc -l`"
  else
      no_hardlink_events='downloaded to:|symlinked to|removed|written from message'
      all_events="hardlink|$no_hardlink_events"
      countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_rabbitmqtt_f31_*.log | grep -v DEBUG | wc -l`"
  fi
  totsubrmqtt="${tot}"

  countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_u_sftp_f60_*.log | grep -v DEBUG | wc -l`"
  totsubu="${tot}"
  countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_cp_f61_*.log | grep -v DEBUG | wc -l`"
  totsubcp="${tot}"

  if [ "${sarra_py_version:0:1}" == "3" ]; then
      all_events="directory ok:|downloaded ok:|filtered ok:|written from message ok:"
      countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_ftp_f70_*.log | grep -v DEBUG | wc -l`"
  else
      countthem "`grep -aE "$no_hardlink_events" "$LOGDIR"/${LGPFX}subscribe_ftp_f70_*.log | grep -v DEBUG | wc -l`"
  fi
  totsubftp="${tot}"

  #if [ "${sarra_py_version:0:1}" == "3" ]; then
  #    #countthem "`grep -aE "after_work downloaded ok" "$LOGDIR"/${LGPFX}subscribe_q_f71_*.log | wc -l`"
  #
  # else
  #   countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_q_f71_*.log | grep -v DEBUG | wc -l`"
  #i
  countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_q_f71_*.log | grep -v DEBUG | wc -l`"
  totsubq="${tot}"
  countthem "`grep -aE "$all_events" "$LOGDIR"/${LGPFX}subscribe_q_f71_*.log | grep -v DEBUG | sed 's/.*ok://g' | awk '{ print $1 }' | sort | uniq | wc -l`"
  # need to use uniq because 1) we use uniq values from the poll and 2) subscribe might process some messages twice, if the broker
  # goes down before the subscriber can ack them -- the messages will get re-delivered by the broker even if they've already been
  # successfully "worked" by the subscriber. Since 3.02.00, need awk to remove the size: ... rate: ... suffix.
  totsubq_uniq="${tot}"

  if [ "${sarra_py_version:0:1}" == "3" ]; then
       countthem "`grep -aE 'log after_post posted' "$LOGDIR"/poll_sftp_f62_*.log | wc -l`"
       totpoll2="${tot}"
       countthem "`grep -aE 'log after_post posted' "$LOGDIR"/poll_sftp_f63_*.log | wc -l`"
       totpoll3="${tot}"
       totpoll=$(( ${totpoll2} + ${totpoll3} ))
       totpoll_unique="`grep -aE 'log after_post posted' $LOGDIR/poll_sftp_f6?_*.log | sed 's/.*relPath: //g' | awk '{ print $1 }' | sort -u | wc -l`"
       totpoll_mirrored="`grep -a ', now saved' "$LOGDIR"/poll_sftp_f6*_*.log | awk ' { print $18 } '|tail -1`"
       totpoll_dupes=$(( ${totpoll} - ${totpoll_unique} ))
  else
       countthem "`grep -aE '\[INFO\] post_log' "$LOGDIR"/${LGPFX}poll_sftp_f62_*.log | wc -l`"
       totpoll2="${tot}"
       countthem "`grep -aE '\[INFO\] post_log' "$LOGDIR"/${LGPFX}poll_sftp_f63_*.log | wc -l`"
       totpoll3="${tot}"
       totpoll=$(( ${totpoll2} + ${totpoll3} ))
  fi

  shimpostlog=${LOGDIR}/allshimposts.log

  if [ "${sarra_py_version:0:1}" == "3" ]; then
       countthem "`grep -a 'log after_post posted' $srposterlog | grep -v shim | wc -l`"
       totpost1="${tot}"
       grep -a '\[INFO\] shim published:' $srposterlog | grep shim >$shimpostlog

       countthem "`grep -a '\[INFO\] shim published:' $srposterlog | grep shim | wc -l`"
       totshimpost1="${tot}"
  else
       countthem "`grep -a '\[INFO\] post_log notice' $srposterlog | grep -v shim | wc -l`"
       totpost1="${tot}"
       grep -a '\[INFO\] published:' $srposterlog | grep shim >$shimpostlog

       countthem "`grep -a '\[INFO\] published:' $srposterlog | grep shim | wc -l`"
       totshimpost1="${tot}"
  fi


  countthem "`grep -a -v \"link\" ${shimpostlog} | grep -a -v \"directory\" | wc -l`"
  totfileshimpost1="${tot}"
  countthem "`grep -a \"link\" ${shimpostlog} | grep -a -v \"directory\" | wc -l`"
  totlinkshimpost1="${tot}"


  grep -a \"link\" ${shimpostlog} | grep -a \"directory\" >${LOGDIR}/totlinkdirshimpost.log
  countthem "`wc -l <${LOGDIR}/totlinkdirshimpost.log`"
  totlinkdirshimpost1="${tot}"

  grep -a \"directory\" ${shimpostlog} | grep -a -v \"link\" >${LOGDIR}/totdirshimpost1.log
  countthem "`wc -l <${LOGDIR}/totdirshimpost1.log`"
  totdirshimpost1="${tot}"

  totshimpost=$((${totfileshimpost1}+${totlinkshimpost1}+${totdirshimpost1}))


  if [ "${sarra_py_version:0:1}" == "3" ]; then
      countthem "`grep -a 'log after_post posted' "$LOGDIR"/${LGPFX}sarra_download_f20_*.log | wc -l`"
      totsarp="${tot}"
  else
      countthem "`grep -a '\[INFO\] post_log notice' "$LOGDIR"/${LGPFX}sarra_download_f20_*.log | wc -l`"
      totsarp="${tot}"
  fi

  if [[ ! "$C_ALSO" && ! -d "$SARRAC_LIB" ]]; then
     return
  fi

  staticdircount="`find ${SAMPLEDATA}/* -type d | grep -v reject | wc -l`"
  staticfilecount="`find ${SAMPLEDATA} -type f | grep -v reject | wc -l`"
  rejectfilecount="`find ${SAMPLEDATA} -type f | grep reject | wc -l`"

  if [[ "${sarra_py_version}" > "3.00.25" ]]; then
      staticfilecount=$((${staticfilecount}+${staticdircount}))
      echo "FIXME: yes dir events"

      countthem "`grep -a '\[INFO\] cpost published:' $LOGDIR/${LGPFX}cpost_pelle_dd1_f04_*.log | wc -l`"
      totcpelle04p="${tot}"

      countthem "`grep -a '\[INFO\] cpost published:' $LOGDIR/${LGPFX}cpost_pelle_dd2_f05_*.log | wc -l`"
      totcpelle05p="${tot}"
  else
      echo "FIXME: No dir events"

      countthem "`grep -a '\[INFO\] published:' $LOGDIR/${LGPFX}cpost_pelle_dd1_f04_*.log | wc -l`"
      totcpelle04p="${tot}"

      countthem "`grep -a '\[INFO\] published:' $LOGDIR/${LGPFX}cpost_pelle_dd2_f05_*.log | wc -l`"
      totcpelle05p="${tot}"
  fi


  countthem "`grep -a 'post_rate_limit' $LOGDIR/${LGPFX}cpost_pelle_dd1_f04_*.log | wc -l`"
  totcpelle04_rl="${tot}"
  if [[ "${totcpelle04_rl}" == 0 ]]; then
      countthem "`grep -a 'messageRateMax' $LOGDIR/${LGPFX}cpost_pelle_dd1_f04_*.log | wc -l`"
      totcpelle04_rl="${tot}"
  fi

  countthem "`grep -a 'post_rate_limit' $LOGDIR/${LGPFX}cpost_pelle_dd2_f05_*.log | wc -l`"
  totcpelle05_rl="${tot}"
  if [[ "${totcpelle05_rl}" == 0 ]]; then
      countthem "`grep -a 'messageRateMax' $LOGDIR/${LGPFX}cpost_pelle_dd1_f04_*.log | wc -l`"
      totcpelle05_rl="${tot}"
  fi

  if [[ "${sarra_c_version}" > "3.22.12p1" ]]; then
      countthem "`grep -a '\[INFO\] cpump published:' $LOGDIR/${LGPFX}cpump_xvan_f14_*.log | grep -v \"directory\" | wc -l`"
      totcvan14p="${tot}"

      countthem "`grep -a '\[INFO\] cpump published:' $LOGDIR/${LGPFX}cpump_xvan_f15_*.log | grep -v \"directory\" | wc -l`"
      totcvan15p="${tot}"

      countthem "`grep -a '\[INFO\] cpost published:' $LOGDIR/${LGPFX}cpost_veille_f34_*.log | grep -v \"directory\" | grep -v '\"size\":\"0\"' | awk '{ print $8 }' | wc -l`"
      totcveille="${tot}"
  else
      countthem "`grep -a '\[INFO\] published:' $LOGDIR/${LGPFX}cpump_xvan_f14_*.log | grep -v \"directory\" | wc -l`"
      totcvan14p="${tot}"

      countthem "`grep -a '\[INFO\] published:' $LOGDIR/${LGPFX}cpump_xvan_f15_*.log | grep -v \"directory\" | wc -l`"
      totcvan15p="${tot}"

      countthem "`grep -a '\[INFO\] published:' $LOGDIR/${LGPFX}cpost_veille_f34_*.log | awk '{ print $7 }' | sort -u |wc -l`"
      totcveille="${tot}"
  fi

  if [ "${sarra_py_version:0:1}" == "3" ]; then
	  countthem "`grep -aE 'after_work downloaded ok' $LOGDIR/${LGPFX}subscribe_cdnld_f21_*.log | wc -l`"
  else
      countthem "`grep -a '\[INFO\] file_log downloaded ' $LOGDIR/${LGPFX}subscribe_cdnld_f21_*.log | wc -l`"
  fi
  totcdnld="${tot}"

  if [ "${sarra_py_version:0:1}" == "3" ]; then
      countthem "`grep -a 'after_work downloaded ok' $LOGDIR/${LGPFX}subscribe_cfile_f44_*.log | wc -l`"
      # zero byte files should not be counted.
      zerobytefilesxferred="`grep 0--1 $LOGDIR/${LGPFX}subscribe_cfile_f44_*.log | wc -l`"
      tot=$((${tot}-${zerobytefilesxferred}))
  else
      countthem "`grep -a '\[INFO\] file_log downloaded ' $LOGDIR/${LGPFX}subscribe_cfile_f44_*.log | wc -l`"
  fi
  totcfile="${tot}"

  if [[ $(ls "$LOGDIR"/${LGPFX}shovel_pclean_f90*.log 2>/dev/null) ]]; then
      countthem "`grep '\[INFO\] post_log notice' "$LOGDIR"/${LGPFX}shovel_pclean_f90*.log | wc -l`"
      totpropagated="${tot}"
  else
      totpropagated="0"
  fi

  if [[ $(ls "$LOGDIR"/${LGPFX}shovel_pclean_f92*.log 2>/dev/null) ]]; then
      countthem "`grep '\[INFO\] post_log notice' "$LOGDIR"/${LGPFX}shovel_pclean_f92*.log | wc -l`"
      totremoved="${tot}"
  else
      totremoved="0"
  fi

  # flags when two lines include *msg_log received* (with no other message between them) indicating no user will know what happenned.
  awk 'BEGIN { lr=0; }; /msg_log received/ { lr++; print lr, FILENAME, $0 ; next; }; { lr=0; } '  $LOGDIR/${LGPFX}subscribe_*_f??_??.log  | grep -v '^1 ' >$missedreport
  missed_dispositions="`wc -l <$missedreport`"

}

 
messages_unacked="`rabbitmqadmin -H localhost -u bunnymaster -p ${adminpw} list queues name messages_unacknowledged | awk ' BEGIN {t=0;} (NR > 1)  && /_f[0-9][0-9]/ { t+=$4; }; END { print t; };'`"
messages_ready="`rabbitmqadmin -H localhost -u bunnymaster -p ${adminpw} list queues name messages_ready | awk ' BEGIN {t=0;} (NR > 1)  && /_f[0-9][0-9]/ { t+=$4; }; END { print t; };'`"



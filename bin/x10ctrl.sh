#!/bin/bash
#
#   Copyright 2017 M Hightower
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# x10ctrl.sh
#
# Simple script to feed a name pipe with br (bottle rocket a command line tool
# to drive X10 firecracker) commands. Starts a background service, if needed, 
# to slowly draw form pipe and call br to process the requests. Warning: 
# There are bugs here. I don't know where they are, 
# but they are always there - somewhere.

# brcmdprefix="-x /dev/firecracker"
brcmdprefix=
namesh=`basename $0`
namebase=`basename $0 .sh`
logfile=`dirname $0`
logfile=`dirname $logfile`/log/$namebase.log
mutex=/tmp/$namesh.init.mutex
pipe=/tmp/$namebase/${namebase}_fifo
pipedir=`dirname $pipe`
interCmdGap=0.18

usage(){
  cat <<EOF
Usage:

  $namesh [br command line parameters | --status | --stop | ...]

  Supported operations:

    --getpipe
      Returns the name of the pipe that is being used.

    --start
      Starts backgroud service. Not necessary. Background service will be
      started if not running, when called with a br command line.

    --status
      Reports if service is running.

    --stop
      Places a stop request in the backgroud service's pipe.

    --service
      Internal do not use. The script will internally call --service,
      when the background service needs to be started. Could be used
      for debugging to run service in a window by itself.

    --help
      This usage message.
EOF
  return 1
}

status(){
    echo "Status:"
    if [[ -p $pipe ]]; then
      echo "Service's named pipe, $pipe, is present."
      statusResult=1
    else
      echo "Service's named pipe, $pipe, is missing."
      statusResult=0
    fi
    ServiceCount=`ps ax | grep "$namesh --service" | grep -cv "grep"`
    statusResult=$((statusResult + $ServiceCount * 10))
    if [[ $ServiceCount -eq 1 ]]; then
      echo "Background service is running."
    elif [[ $ServiceCount -gt 1 ]]; then
      echo "Too many services running."
    else
      echo "Background service is not running."
    fi
    echo "Status results: $statusResult"
    return $statusResult
}

stop() {
  if [[ -p $pipe ]]; then
    echo "--stop">>$pipe
    echo `date +"%b %d %T"` "que --stop" >>$logfile
    echo "Stop service request placed in fifo."
    sleep 0.2
  else
    echo `date +"%b %d %T"` "$namesh $1, no pipe present.">>$logfile
  fi
  status
  if [[ $statusResult -eq 0 ]]; then
    echo "Success"
  fi
  return 1
}

queRequest() {
  if [[ ! -p $pipe ]]; then
    echo  `date +"%b %d %T"` "starting $namesh" >>$logfile
    nohup $0 --service >>$logfile 2>&1 &
    sleep 1;

    status
    if [[ $statusResult -eq 11 ]]; then
      echo "Background service started."
    else
      echo "Background service failed to start."
      echo `date +"%b %d %T"` "\"$*\", Start failed">>$logfile
      return 0
    fi
  fi

  if [[ -n "$*" ]]; then
    echo `date +"%b %d %T"` "que $*" >>$logfile
    echo -en "$*\n">>$pipe
  fi
  return 1
} # main()


service() {

  if [[ -p $pipe ]]; then
    # When name pipe already exist, we assume an instance of the service
    # is already running.
    return 1
  fi
  if ! (mkdir $mutex); then
    # An instance of the service is in the process of starting - get out.
    return 1
  fi
  trap "rmdir $mutex" EXIT

  # Cleanup accidental writes
  if [[ -f $pipe ]]; then
    rm $pipe
  fi
  if [[ -f $pipedir ]]; then
    rm $pipedir
  fi
  if [[ ! -d $pipedir ]]; then
    mkdir $pipedir
  fi

  if ( mkfifo $pipe ); then
    rmdir $mutex
    trap "rm -f $pipe; rm -fd $pipedir" EXIT

    while true
    do

      if [[ ! -p $pipe ]]; then
        echo `date +"%b %d %T"` "Named pipe, $pipe, missing.">>$logfile
        break;
      fi

      if read -u 3 line; then
        if [[ "$line" = "--stop" ]]; then
          echo `date +"%b %d %T"` "$namesh stopping.">>$logfile
          break
        fi
        echo `date +"%b %d %T"` br $line >>$logfile

        {
           /usr/bin/br $brcmdprefix $line 3</dev/null 3>/dev/null 4</dev/null 4>/dev/null
           sleep $interCmdGap # delay needed for back to back RF based X10 commands to work.
        }>>$logfile 2>&1

      else
        echo oops
        sleep 1
      fi
    done 3< "$pipe" 4> "$pipe"
    return 1
  else
    return 1 # previously defined trap should clear mutex
  fi
}

getpipe() {
  echo "$pipe"
  return 1
}

if [[ "${1:0:2}" = "--" ]]; then
  case "$1" in
  --service)
    service
    ;;
  --status)
    status
    ;;
  --stop)
    stop
    ;;
  --help)
    usage
    ;;
  --start)
    queRequest
    ;;
  --getpipe)
    getpipe
    ;;
  *)
    queRequest $*
    ;;
  esac
elif [[ "${1:0:1}" = "-" ]]; then
  case "$1" in
  -h)
    usage
    ;;
  *)
    queRequest $*
    ;;
 esac
else
  queRequest $*
fi
exit 0


# References:
# https://unix.stackexchange.com/questions/68146/what-are-guarantees-for-concurrent-writes-into-a-named-pipe
# "... writes of {PIPE_BUF} or fewer bytes shall be atomic"
# "... On Linux, it's 4096 bytes (see pipe(7))"
# http://www.linuxjournal.com/article/2156
# http://www.linuxjournal.com/content/using-named-pipes-fifos-bash
# https://stackoverflow.com/questions/4290684/using-named-pipes-with-bash-problem-with-data-loss
# habridge@ha:/opt/habridge/bin $


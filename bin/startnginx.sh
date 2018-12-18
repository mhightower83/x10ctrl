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
unset serverPort

# ha-bridge defaults to port 80, via authbind. If you are using NGINX, un-comment serverPort.
serverPort="8088"

homeDir=/opt/habridge
configFile=/etc${homeDir}/habridge.config
logfile=${homeDir}/log/habridge.log
tmstamp=`date +"%F %T.%N"`
tmstamp="${tmstamp:0:23}"
echo "${tmstamp} -------- Started $0 log ---------">$logfile
cd ${homeDir}
echo "${tmstamp} whoami `whoami`">>$logfile
chmod 666 $logfile

function getCurrentIp {
  # sed jason edit based on https://gist.github.com/shadowbrain/1486478
  ipv4_current=$( sed -n 's/.*"upnpconfigaddress"\s*:\s*"\([^"]*\)".*/\1/p' ${configFile} )
}

function checkInterface {
  [[ -s /var/run/dhcpcd/ipv4_interface/$1 ]] && eval `cat /var/run/dhcpcd/ipv4_interface/$1` && usingNet=$1
}

if [[ -f ${homeDir}/bin/autoUpdateConfig ]]; then
  unset ipv4_address upnpaddress usingNet ipv4_current
  checkInterface wlan0
  checkInterface eth0   # eth0 has presendence
  getCurrentIp

  if [[ -n "${ipv4_address}" ]] && [[ "${ipv4_address}" != "${ipv4_current}" ]]; then
    sed -i "s/\"upnpconfigaddress\"\s*:\s*\"[0-9\.]*\"/\"upnpconfigaddress\":\"${ipv4_address}\"/" ${configFile}
    echo "${tmstamp} Updated value of \"upnpconfigaddress\" in ${configFile} with ${usingNet}:${ipv4_address}" >>$logfile
  fi
fi

[[ -n "${serverPort}" ]] && serverPort="-Dserver.port=${serverPort}"

# nohup authbind --deep java \

nohup java \
      -jar \
      -Dconfig.file=${configFile} \
      ${serverPort} \
      ${homeDir}/bin/ha-bridge.jar >>$logfile 2>&1

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
logfile=/opt/habridge/log/habridge.log
echo "`date +"%b %d %T"` -------- Started $0 log ---------">$logfile
cd /opt/habridge
echo "`date +"%b %d %T"` whoami `whoami`">>$logfile
chmod 666 $logfile
nohup authbind --deep java \
      -jar \
      -Dconfig.file=/etc/opt/habridge/habridge.config \
      /opt/habridge/bin/ha-bridge.jar >>$logfile 2>&1

#     -Dserver.port=8080 \ # <port number> needed if port 80 is already in use and first time running

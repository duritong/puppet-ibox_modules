#!/bin/bash

DB=$1
REMOTE=$2

if [ -z $DB ] || [ -z $REMOTE ]; then
  echo "USAGE: ${0} database remotehost"
  exit 1
fi

export DB
mysql -Bse 'show databases;' | grep -q "^${DB}$"
if [ $? -gt 0 ]; then
  echo "Can't find DB $DB on local server. Aborting..."
  exit 1
fi

REMOTE_IP=`python -c "import socket; print socket.gethostbyname('$REMOTE')"`
iptables -I fw2net 1 -d $REMOTE_IP -p tcp -m tcp --dport 22 -j ACCEPT

ssh root@$REMOTE  "mysql -Bse 'show databases;'" | grep -q "^${DB}$"
if [ $? -gt 0 ]; then
  echo "Can't find DB $DB on local server. Aborting..."
  ret=1
else
  echo "Migrating..."
  mysqldump --add-drop-database --databases $DB | gzip -c | ssh root@$REMOTE "gunzip -c | mysql $DB"
  ret=$?
  echo "Finished..."
fi
unset DB

iptables -D fw2net -d $REMOTE_IP -p tcp -m tcp --dport 22 -j ACCEPT
exit $ret


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
iptables-save | grep -q fw2net
if [ $? -gt 0 ]; then
  chain='fw-net'
else
  chain='fw2net'
fi

REMOTE_IP=`python -c "import socket; print socket.gethostbyname('$REMOTE')"`
iptables -I $chain 1 -d $REMOTE_IP -p tcp -m tcp --dport 22 -j ACCEPT

ssh root@$REMOTE  "mysql -Bse 'show databases;'" | grep -q "^${DB}$"
if [ $? -gt 0 ]; then
  echo "Can't find DB $DB on remote server. Aborting..."
  ret=1
else
  echo "Migrating..."
  mysqldump --add-drop-database --databases $DB | gzip -c | ssh root@$REMOTE "gunzip -c | mysql $DB"
  ret=$?
  echo "Finished..."
fi
unset DB

iptables -D $chain -d $REMOTE_IP -p tcp -m tcp --dport 22 -j ACCEPT
exit $ret


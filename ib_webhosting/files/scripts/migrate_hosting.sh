#!/bin/bash

HOSTING_BASE=/var/www/vhosts
HOSTING=$1
REMOTE=$2

if [ -z $HOSTING ] || [ -z $REMOTE ]; then
  echo "USAGE $0 hosting targethost"
  exit 1
fi

if [ ! -d $HOSTING_BASE/$HOSTING ]; then
  echo "Local hosting does not exist! Aborting..."
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
ssh root@$REMOTE 'test -d $HOSTING_BASE/$HOSTING'
if [ $? -gt 0 ]; then
  echo "Remote hosting does not exist! Aborting..."
  RET=1
else
  echo "Migrating..."
  RET=0
  for dir in www private data backup; do
    if [ -d $HOSTING_BASE/$HOSTING/$dir ]; then
      rsync -e 'ssh' -a --delete $HOSTING_BASE/$HOSTING/$dir root@$REMOTE:$HOSTING_BASE/$HOSTING/ $3
      r=$?
      [ $r -gt 0 ] && RET=$r
    fi
  done
  echo "Finished..."
fi
iptables -D $chain -d $REMOTE_IP -p tcp -m tcp --dport 22 -j ACCEPT
exit $RET


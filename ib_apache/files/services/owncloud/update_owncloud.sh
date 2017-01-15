#!/bin/bash

if [ -z $1 ]; then
  echo "USAGE: $0 name_of_oc_installation||all"
  exit 1
fi

basedir=/var/www/vhosts/
if [ $1 = 'all' ]; then
  ocs=''
  for i in $(ls $basedir/*/www/occ); do
    name=$(basename $(dirname $(dirname $i)))
    ocs="${ocs}${name} "
  done
else
  ocs=$@
fi

function run_cmd_as {
  run_user=$1
  cmd=$2

  su -s /bin/bash $run_user -c "${cmd}"
  res=$?
  [ $res -gt 0 ] && abort "Comand failed with exitcode ${res}"
}

function abort {
  echo $1
  echo "Aborting..."
  exit 1
}

function update_oc {
  oc=$1
  baseocdir=$basedir/$oc
  wwwdir=$baseocdir/www
  datadir=$baseocdir/data/owncloud
  occ=$wwwdir/occ
  if [ ! -f $occ ]; then
    abort "Owncloud ${oc} does not exist!"
  fi

  ftpuser=$(stat -c%U $wwwdir)
  runuser=$(stat -c%U $datadir/index.html)

  echo "Updating $oc"
  chown $runuser ${wwwdir} -R
  occ_wrap $oc 'maintenance:mode --on'
  run_cmd_as $runuser "cd ${wwwdir} && git checkout .htaccess && git pull -q && chmod g+w config -R"
  occ_wrap $oc upgrade
  occ_wrap $oc 'maintenance:mode --off'
  chown $ftpuser ${wwwdir} -R
  run_cmd_as $ftpuser "chmod g+w ${wwwdir}/config -R"
  echo "Updating $oc done"
}

for oc in $ocs; do
  update_oc $oc
done


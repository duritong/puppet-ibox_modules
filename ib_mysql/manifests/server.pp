# a mysql server configuration
class ib_mysql::server(
  $root_password             = 'trocla',
  $munin_password            = 'trocla',
  $admin_users               = {},
  $admin_user_defaults       = {
    password  => 'trocla',
    host      => '127.0.0.1',
  },
  $manage_disks              = true,
  $default_databases         = {},
  $default_database_defaults = {
    password => 'trocla',
  },
) {
  include ::ibox

  if $root_password == 'trocla' {
    $mysql_root_pwd = trocla("mysql_root_${::fqdn}",'plain', 'length: 32')
  } else {
    $mysql_root_pwd = $root_password
  }
  if $munin_password == 'trocla' and $ibox::use_munin {
    $mysql_munin_pwd = trocla("mysql_munin_${::fqdn}",'plain', 'length: 32')
  } else {
    $mysql_munin_pwd = $munin_password
  }

  class{'::mysql::server':
    root_password     => $mysql_root_pwd,
    manage_shorewall  => $ibox::use_shorewall,
    manage_munin      => $ibox::use_munin,
    munin_password    => $mysql_munin_pwd,
    backup_cron       => hiera('mysql::server::backup_cron',true),
    optimize_cron     => hiera('mysql::server::optimize_cron',true),
    # mainly for centos
    manage_backup_dir => false,
    backup_dir        => '/var/lib/mysql/backups',
  }

  include ::mysql::server::tuner

  # as we go with one file per innodb table
  # we need to raise the overall limit
  limits::entry{
    'mysql_server':
      user        => 'mysql',
      limit_type  => 'nofile',
      hard        => '8192',
      soft        => '1200',
      require     => Package['mysql-server'],
      notify      => Service['mysql'];
  }

  create_resources('mysql::admin_user',$admin_users,$admin_user_defaults)

  if $manage_disks {
    include ::ib_disks::datavgs::mysql
  }

  file{'/usr/local/sbin/migrate_mysql_db.sh':
    source  => 'puppet:///modules/ib_mysql/scripts/migrate_mysql_db.sh',
    owner   => root,
    group   => 0,
    mode    => '0500';
  }
  create_resources('mysql::default_database',$default_databases,
    $default_database_defaults)
}

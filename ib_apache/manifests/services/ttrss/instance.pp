# install a ttrss installation
define ib_apache::services::ttrss::instance(
  $ensure           = 'present',
  $domainalias      = 'absent',
  $ssl_mode         = 'force',
  $php_installation = 'scl56',
  $configuration    = {},
  $ttrss_config     = {
    'dbhost' => 'localhost',
  },
) {

  require ib_apache::services::ttrss::base

  webhosting::php{
    $name:
      ensure           => $ensure,
      domainalias      => $domainalias,
      php_installation => $php_installation,
      run_mode         => 'fcgid',
      nagios_use       => 'http-service',
      uid              => 'iuid',
      run_uid          => 'iuid',
      password         => 'trocla',
      wwwmail          => true,
      configuration    => $configuration,
      ssl_mode         => $ssl_mode,
  }

  if versioncmp($operatingsystemmajrelease,'6') > 0 {
    service{"ttrss@${name}": }
  }
  if $ensure == 'present' {
    #ttrss stuff
    include ::shorewall::rules::out::imap
    git::clone{
      "ttrss@${name}":
        git_repo        => 'https://git.immerda.ch/ittrss.git',
        projectroot     => "/var/www/vhosts/${name}/www",
        branch          => 'immerda',
        cloneddir_user  => $name,
        cloneddir_group => $name,
        require         => File["/var/www/vhosts/${name}"],
    } -> file{
      "/var/www/vhosts/${name}/www/config.php":
        content => template('ib_apache/services/ttrss/config.php.erb'),
        owner   => $name,
        group   => $name,
        mode    => '0640';
      "/var/www/vhosts/${name}/data/update_daemon.sh":
        content => template('ib_apache/services/ttrss/update_daemon.erb'),
        owner   => $name,
        group   => $name,
        mode    => '0750';
      [ "/var/www/vhosts/${name}/www/lock", "/var/www/vhosts/${name}/www/cache",
        "/var/www/vhosts/${name}/www/cache/upload",
        "/var/www/vhosts/${name}/www/cache/htmlpurifier",
        "/var/www/vhosts/${name}/www/cache/images",
        "/var/www/vhosts/${name}/www/cache/js",
        "/var/www/vhosts/${name}/www/cache/export",
        "/var/www/vhosts/${name}/www/feed-icons",
        "/var/www/vhosts/${name}/tmp" ]:
        ensure  => directory,
        require => File["/var/www/vhosts/${name}/www/config.php"],
        owner   => $name,
        group   => $name,
        mode    => '0770';
    }
    if versioncmp($operatingsystemmajrelease,'6') > 0 {
      Service["ttrss@${name}"]{
        ensure  => running,
        enable  => true,
        subscribe => File['/etc/systemd/system/ttrss@.service',"/var/www/vhosts/${name}/data/update_daemon.sh","/var/www/vhosts/${name}/www/config.php"],
      }
      if $ttrss_config['dbhost'] in ['localhost','127.0.0.1','::1'] {
        Mysql_database<| title == $db_name |>  -> Git::Clone["ttrss@${name}"]
        Mysql_user<| title == $real_db_user |> -> Git::Clone["ttrss@${name}"]
      }
    }
  } else {
    if versioncmp($operatingsystemmajrelease,'6') > 0 {
      Service["ttrss@${name}"]{
        ensure  => stopped,
        enable  => false,
      }
    }
  }
}

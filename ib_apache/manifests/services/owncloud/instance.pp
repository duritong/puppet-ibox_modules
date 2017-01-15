# an owncloud installation
define ib_apache::services::owncloud::instance(
  $ensure             = 'present',
  $configuration      = {},
  $nagios_check       = 'ensure',
  $disk_size          = false,
  $config             = false,
  $php_settings       = {},
  $upload_options     = 'FcgidMaxRequestLen 1048576
    SSLRenegBufferSize 1048576',
  $additional_options = '',
  # so that we can set this from external
  $default_dbhost     = 'localhost',
  $ssl_mode           = 'force',
  $nagios_use         = 'generic-service',
){

  # TODO: cron

  require ::ib_apache::services::owncloud::base
  $php_installation = $ib_apache::services::owncloud::base::php_installation
  webhosting::php{
    $name:
      ensure       => $ensure,
      ssl_mode     => $ssl_mode,
      run_mode     => 'fcgid',
      uid          => 'iuid',
      run_uid      => 'iuid',
      password     => 'trocla',
      nagios_check => $nagios_check,
      nagios_use   => $nagios_use,
      wwwmail      => true;
  }
  if $disk_size {
    disks::lv_mount{
      "oc-${name}":
        ensure => $ensure,
        size   => $disk_size,
        folder => "/var/www/vhosts/${name}/data/owncloud",
    }
  }
  file{"/etc/logrotate.d/oc_${name}": }
  if $ensure != 'absent' {
    $inst = regsubst($php_installation,'^scl','php')
    require "::php::scl::${inst}"

    Webhosting::Php[$name]{
      configuration         => $configuration,
      watch_adjust_webfiles => 'absent',
      php_installation      => $php_installation,
      allow_override        => 'All',

      options            => '+Indexes +FollowSymLinks',
      additional_options => "<Location />
    Dav Off
  </Location>
  ${upload_options}
  ${additional_options}",
      php_settings => merge($php_settings,{
        upload_max_filesize => '1G',
        post_max_size       => '1G',
        max_input_time      => 3600,
        max_execution_time  => 3600,
        memory_limit        => '1G',
        safe_mode           => false,
        open_basedir        => undef,
        allow_url_fopen     => on,
      }),
    }

    git::clone{
      "owncloud_${name}":
        git_repo        => 'https://git.immerda.ch/iowncloud.git',
        branch          => 'immerda',
        submodules      => true,
        projectroot     => "/var/www/vhosts/${name}/www",
        cloneddir_user  => $name,
        cloneddir_group => $name,
        require         => File["/var/www/vhosts/${name}"],
        clone_before    => File["/var/www/vhosts/${name}/www"];
    }
    if $disk_size {
      Disks::Lv_mount["oc-${name}"]{
        owner   => $name,
        group   => $name,
        mode    => '0770',
        before  => File["/var/www/vhosts/${name}/www/config"],
        require => [ User::Managed[$name], File["/var/www/vhosts/${name}/data"] ],
      }
    } else {
      file{
        "/var/www/vhosts/${name}/data/owncloud":
          ensure  => directory,
          owner   => $name,
          group   => $name,
          mode    => '0660',
          require => User::Managed[$name],
      }
    }

    file{
      [ "/var/www/vhosts/${name}/www/config",
        "/var/www/vhosts/${name}/www/apps",
        "/var/www/vhosts/${name}/www/data" ]:
        ensure  => directory,
        owner   => $name,
        group   => $name,
        mode    => '0660',
        require => Git::Clone["owncloud_${name}"],
        before  => Service['apache'];
    }
    File["/etc/logrotate.d/oc_${name}"]{
      content => template('ib_apache/services/owncloud/logrotate.erb'),
      owner   => root,
      group   => 0,
      mode    => '0644'
    }

    if $config {
      if !('dbname' in $config) {
        fail('Config item dbname is required')
      }
      $default_config = {
        dbtype            => 'mysql',
        dbuser            => $config['dbname'],
        dbhost            => $default_dbhost,
        dbpass            => trocla("mysql_${config['dbname']}",'plain'),
        adminpass         => trocla("owncloud_${name}",'plain'),
        adminlogin        => 'root',
        mail_domain       => hiera('owncloud::mail_domain',$::domain),
        mail_from_address => 'owncloud',
      }
      $oc_config = merge($default_config, $config)
      file {
        "/var/www/vhosts/${name}/www/config/autoconfig-init.php":
          replace => false,
          content => template('ib_apache/services/owncloud/autoconfig.php.erb'),
          owner   => $name,
          group   => $name,
          mode    => '0660',
          notify  => Exec["owncloud_autoconfig_${name}"];
        "/var/www/vhosts/${name}/www/config/managed.config.php":
          content => template('ib_apache/services/owncloud/managedconfig.php.erb'),
          owner   => $name,
          group   => $name,
          mode    => '0640',
          before  => Exec["owncloud_autoconfig_${name}"];
      }

      exec{"owncloud_autoconfig_${name}":
        command     => "cp -a /var/www/vhosts/${name}/www/config/autoconfig-init.php /var/www/vhosts/${name}/www/config/autoconfig.php && echo 'installed' > /var/www/vhosts/${name}/www/config/autoconfig-init.php",
        user        => $name,
        group       => $name,
        refreshonly => true,
        require     => File["/var/www/vhosts/${name}/www/config"],
        before      => Service['apache'],
      }
      if $oc_config['dbhost'] in ['localhost','127.0.0.1','::1'] {
        $dbname = $oc_config['dbname']
        $dbuser = $oc_config['dbuser']
        Mysql_database<| title == $dbname |>  -> Exec["owncloud_autoconfig_${name}"]
        Mysql_user<| title == $dbuser |> -> Exec["owncloud_autoconfig_${name}"]
      }
    }
  } else {
    if $disk_size {
      Logical_volume["oc-${name}"] -> Webhosting::Php[$name]
    }
    File["/etc/logrotate.d/oc_${name}"]{
      ensure => absent,
    }
  }
}

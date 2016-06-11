# manage a coquelicot instance
define ib_apache::services::coquelicot::instance(
  $domainalias = 'absent',
  $ensure      = 'present',
  $lvsize      = '5G',
  $config      = {},
  $git_repo    = 'https://git.immerda.ch/coquelicot.git',
  $branch      = 'master',
  $uid         = 'iuid',
  $port        = 5100+fqdn_rand(300,$name),
){
  require ::ib_apache::services::coquelicot::base
  $base_path = "${ib_apache::services::coquelicot::base::base_path}/${name}"
  service{"coquelicot@${name}": }
  disks::lv_mount{"cq_${name}":
    ensure => $ensure,
    folder => "${base_path}/data",
  }
  user::managed{$name:
    ensure     => $ensure,
    managehome => false,
    homedir    => $base_path,
  }
  apache::vhost::proxy{$name:
    ensure  => $ensure,
    backend => "http://127.0.0.1:${port}",
  }
  anchor{"coquelicot::unqiue_port::${port}": }
  if $ensure == 'present' {
    require ::ruby::bundler
    require ::ruby::devel
    ensure_packages(['libxml2-devel'])
    $real_uid = $uid ? {
      'iuid'  => iuid($name,'webhosting'),
      default => $uid,
    }

    User::Managed[$name]{
      shell => '/sbin/nologin',
      uid   => $real_uid,
    }
    file{
      $base_path:
        ensure  => directory,
        require => User::Managed[$name],
        owner   => root,
        group   => $name,
        mode    => '0644';
      [ "${base_path}/log", "${base_path}/data/tmp",
        "${base_path}/data/tmp/cache","${base_path}/data/files" ]:
        ensure  => directory,
        owner   => $name,
        group   => $name,
        mode    => '0640',
        before  => Service["coquelicot@${name}"];
      "${base_path}/app/conf/settings.yml":
        content => template('ib_apache/services/coquelicot/settings.yml.erb'),
        require => Git::Clone[$name],
        owner   => root,
        group   => $name,
        mode    => '0640',
        notify  => Service["coquelicot@${name}"],
    }
    Disks::Lv_mount["cq_${name}"]{
      size    => $lvsize,
      owner   => $name,
      group   => $name,
      mode    => '0640',
      require => File[$base_path],
      before  => Service["coquelicot@${name}"],
    }
    git::clone{
      $name:
        git_repo        => $git_repo,
        projectroot     => "${base_path}/app",
        branch          => $branch,
        cloneddir_group => $name,
        require         => User::Managed[$name],
    } ~> exec{"chown -R ${name}:${name} ${base_path}/app":
      refreshonly => true,
    } ~> exec{"git update-server-info ${name}":
      command     => "git update-server-info",
      refreshonly => true,
      cwd         => "${base_path}/app",
      user        => $name,
    } -> exec{"bundle_${name}":
      command     => 'bundle install --deployment',
      cwd         => "${base_path}/app",
      refreshonly => true,
      subscribe   => Git::Clone[$name],
      user        => $name,
      require     => Package['libxml2-devel'],
      notify      => Service["coquelicot@${name}"],
    } ~> exec{"fix_appdir_perms_${name}":
      command     => "chown -R root:${name} ${base_path}/app && chmod -R o-rwx,g-w,g+rX ${base_path}/app",
      refreshonly => true,
    } -> Service["coquelicot@${name}"]{
      ensure => running,
      enable => true,
    } -> Apache::Vhost::Proxy[$name]{
      ssl_mode           => 'force',
      logmode            => "noip",
      additional_options => 'SetEnv proxy-sendchunks 1
  RequestHeader set X-Forwarded-SSL "on"',
    }
    file{"${base_path}/app/.git/hooks/post-update":
      content => '#!/bin/sh
exec git update-server-info
',
      owner   => root,
      group   => $name,
      mode    => '0750',
      require => Exec["fix_appdir_perms_${name}"],
    }
  } else {
    Service["coquelicot@${name}"]{
      ensure => stopped,
      enable => false,
      before => Disks::Lv_mount["cq_${name}"],
    }
    exec{"rm -rf ${base_path}":
      unless  => "test -d ${base_path}",
      require => Disks::Lv_mount["cq_${name}"],
    }
  }
}

# manage a coquelicot instance
define ib_apache::services::coquelicot::instance(
  $domainalias   = 'absent',
  $ensure        = 'present',
  $lvsize        = '10G',
  $config        = {
    additional_css        => ['layout/css/immerda.css','layout/css/coquelicot.css'],
    max_file_size         => 209715200,
    about_text            => {
      en           => 'Read more about dl.immerda.ch in our <a href=\"https://www.immerda.ch/info/2011/08/12/neuer-service-dateien-austauschen.html\">initial blog post</a>. This service is exclusively for immerda users and you need to provide your immerda login credentials.<br/><br/><b>Limited to 200MB!</b>',
      de           => 'Erfahre mehr zu dl.immerda.ch in unserem <a href=\"https://www.immerda.ch/info/2011/08/12/neuer-service-dateien-austauschen.html\">Blogartikel</a> dazu. Du musst dich mit deinem immerda-Konto anmelden um diesen Service zu nutzen.<br/><br/><b>Limitiert auf 200MB!</b>'
    },
    authentication_method => {
      imap_port   => 993,
      imap_server => 'imap.immerda.ch',
      name        => 'imap',
    }
  },
  $git_repo      = 'https://git.immerda.ch/coquelicot.git',
  $branch        = 'master',
  $layout_repo   = 'https://git.immerda.ch/web/layout.immerda.ch.git',
  $layout_branch = 'master',
  $uid           = 'iuid',
  $port          = 5100+fqdn_rand(300,$name),
){
  require ::ib_apache::services::coquelicot::base
  $base_path = "${ib_apache::services::coquelicot::base::base_path}/${name}"
  service{"coquelicot@${name}": }
  disks::lv_mount{"cq_${name}":
    ensure => $ensure,
    folder => $base_path,
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
  file{"/etc/cron.d/coquelicot_gc_${name}.sh": }
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
    Disks::Lv_mount["cq_${name}"]{
      size    => $lvsize,
      owner   => $name,
      group   => $name,
      mode    => '0640',
      require => User::Managed[$name],
      before  => Service["coquelicot@${name}"],
    }
    file{
      [ "${base_path}/data", "${base_path}/log", "${base_path}/data/tmp",
        "${base_path}/data/tmp/cache","${base_path}/data/files" ]:
        ensure  => directory,
        owner   => $name,
        group   => $name,
        mode    => '0640',
        before  => Service["coquelicot@${name}"];
      "${base_path}/app/conf/settings.yml":
        content => template('ib_apache/services/coquelicot/settings.yml.erb'),
        owner   => root,
        group   => $name,
        mode    => '0640',
        require => Exec["fix_appdir_perms_${name}"],
        notify  => Service["coquelicot@${name}"],
    }
    git::clone{
      $name:
        git_repo        => $git_repo,
        projectroot     => "${base_path}/app",
        branch          => $branch,
        cloneddir_group => $name,
        require         => Disks::Lv_mount["cq_${name}"],
    } ~> exec{"chown_${name}":
      command     => "chown -R ${name}:${name} ${base_path}/app",
      refreshonly => true,
    } ~> exec{"git update-server-info ${name}":
      command     => 'git update-server-info',
      refreshonly => true,
      cwd         => "${base_path}/app",
      user        => $name,
    } -> exec{"bundle_${name}":
      command     => 'bundle install --deployment',
      cwd         => "${base_path}/app",
      refreshonly => true,
      subscribe   => Git::Clone[$name],
      timeout     => 600,
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
      logmode            => 'noip',
      additional_options => 'SetEnv proxy-sendchunks 1
  RequestHeader set X-Forwarded-SSL "on"',
    } -> File["/etc/cron.d/coquelicot_gc_${name}.sh"]{
      content => "*/5 * * * * ${name} cd ${base_path}/app && bundle exec coquelicot gc\n",
      owner   => root,
      group   => 0,
      mode    => 0644,
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
    if $layout_repo {
      git::clone{
        "layout_${name}":
          git_repo        => $layout_repo,
          projectroot     => "${base_path}/app/public/layout",
          branch          => $layout_branch,
          cloneddir_group => $name,
          require         => Git::Clone[$name],
          before          => Exec["chown_${name}"],
      }
    }
    if $config['authentication_method'] and ($config['authentication_method']['name'] == 'imap') {
      include ::shorewall::rules::out::imap
    }
  } else {
    Service["coquelicot@${name}"]{
      ensure => stopped,
      enable => false,
      before => Disks::Lv_mount["cq_${name}"],
    }
    File["/etc/cron.d/coquelicot_gc_${name}.sh"]{
      ensure => absent,
    }
    exec{"rm -rf ${base_path}":
      unless  => "test -d ${base_path}",
      require => Disks::Lv_mount["cq_${name}"],
    }
  }
}

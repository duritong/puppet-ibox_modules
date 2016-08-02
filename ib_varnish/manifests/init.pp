# a varnish that
class ib_varnish(
  $default_config_files = [
    'backends',
    'custom_backends',
    'custom_fetch',
    'custom_recv',
    'directors',
    'error',
    'setup',
    'vhosts-common.fetch_footer',
    'vhosts-common.fetch_header',
    'vhosts-common.fetch_inline',
    'vhosts-common.recv_footer',
    'vhosts-common.recv_header',
    'vhosts-fetch',
    'vhosts-recv',
  ],
  $config_files         = {},
) {
  include ::ib_disks::datavgs::varnish
  class{'::varnish':
    default_config => false,
    manage_munin   => $ibox::use_munin,
  }
  $config_file_keys = union(keys($config_files),$default_config_files)
  varnish::config_file{
    'default':
      source => [
        "puppet:///modules/ib_varnish/config/${::operatingsystem}.${::operatingsystemmajrelease}/default.vcl",
        "puppet:///modules/ib_varnish/config/default.vcl",

      ],
  }
  ib_varnish::config_file{
    $config_file_keys:
      sources => $config_files,
  }

  package{'varnishHostStat':
    ensure  => present,
    require => Package['varnish'],
  }
  $listen_addr = "${::ipaddress}:80,${::ipaddress}:11371,127.0.0.1"
  $listen_port = '8080'
  if (versioncmp($::operatingsystemmajrelease,'6') > 0) {
    file{'/etc/varnish/varnish.params':
      content => template('ib_varnish/varnish.params.erb'),
      require => Package['varnish'],
      notify  => Service['varnish'],
      owner   => root,
      group   => 0,
      mode    => '0644';
    }
  } else {
    $listen_str = "${listen_addr}:${listen_port}"
    file{'/etc/sysconfig/varnish':
      content => template('ib_varnish/sysconfig.erb'),
      require => Package['varnish'],
      notify  => Service['varnish'],
      owner   => root,
      group   => 0,
      mode    => '0640';
    }
  }
  if str2bool($::selinux) {
    selboolean{
      'varnishd_connect_any':
        value      => 'on',
        persistent => true,
        require    => Package['varnish'],
        before     => Service['varnish'];
    }
  }
}

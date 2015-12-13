# a wrapper for the nsd module
#
# === Parameters
#
# $bind_ip_address:: on which ip address bind should listen
# $test_domain:: that should be used for nagios checks
# $zone_src_dir:: if a set of zones should be synced
#
class ib_bind(
  $bind_ip_address = $::ipaddress,
  $test_domain     = $::domain,
  $zone_src_dir    = undef,
) {
  class{'::bind':
    chroot => true,
  }

  file{'/etc/named.conf.src':
    content => template('ib_bind/named.conf.erb'),
    before  => Package['bind9'],
    notify  => Exec['bind_cp_initial_src'];
  }
  exec{
    'bind_cp_initial_src':
      command     => 'cp /etc/named.conf.src /etc/named.conf',
      refreshonly => true,
      before      => Package['bind9'],
      notify      => Exec['reload bind9'];
    'cleanup_rpmnew':
      command     => 'rm /etc/named.conf.rpmnew',
      onlyif      => 'test -f /etc/named.conf.rpmnew',
      refreshonly => true,
      subscribe   => Package['bind9'],
      require     => Service['bind9'];
  }

  if $zone_src_dir {
    file_line {'include auto':
      ensure  => present,
      line    => 'include "/etc/named/named.conf.auto";',
      path    => '/etc/named.conf',
      require => Package['bind9'],
      notify  => Exec['reload bind9'],
    }
    file{
      '/etc/named/named.conf.auto':
        source  => "${zone_src_dir}/zone_list.bind",
        require => Package['bind9'],
        notify  => Exec['reload bind9'],
        owner   => root,
        group   => 0,
        mode    => '0644';
      '/var/named/zones.d':
        ensure  => directory,
        source  => "${zone_src_dir}/zones.d",
        require => Package['bind9'],
        notify  => Exec['reload bind9'],
        owner   => root,
        group   => 0,
        recurse => true,
        purge   => true,
        force   => true,
        ignore  => '*.yaml';
    }
  }

  if $ibox::use_nagios {
    nagios::service::dns{
      "bind_${test_domain}":
        check_domain => $test_domain,
        ip           => $bind_ip_address,
    }
  }
  if $ibox::use_shorewall {
    include ::shorewall::rules::dns
  }
  if $ibox::use_munin {
    munin::plugin{
      'bind9_rndc':
        config => '  group named
  env.querystats      /var/named/data/named_stats.txt
',
    }
  }

  include ::ibox::lib::dns_utils
}

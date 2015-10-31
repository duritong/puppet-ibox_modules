# a wrapper for the nsd module
class ib_nsd(
  $bind_ip_address = $::ipaddress,
  $test_domain     = $::domain,
  $zone_src_dir    = undef,
) {
  if $ibox::use_nagios {
    $nagios_test_domain = $test_domain
  } else {
    $nagios_test_domain = undef
  }
  class{'nsd':
    bind_ip_address    => $bind_ip_address,
    manage_munin       => $ibox::use_munin,
    manage_shorewall   => $ibox::use_shorewall,
    nagios_test_domain => $nagios_test_domain,
  }

  if $zone_src_dir {
    file_line{'zones_include.conf':
      line    => 'include: "/etc/nsd/zone_list.conf"',
      path    => '/etc/nsd/nsd.conf',
      notify  => Exec['rebuild_nsd_config'],
      require => File_line['nsd_conf_includes'],
    }

    file{
      '/etc/nsd/zone_list.conf':
        source  => "${zone_src_dir}/zone_list.conf",
        require => Package['nsd'],
        notify  => Exec['rebuild_nsd_config'],
        owner   => root,
        group   => 0,
        mode    => '0644';
      '/etc/nsd/zones.d':
        ensure  => directory,
        source  => "${zone_src_dir}/zones.d",
        require => Package['nsd'],
        notify  => Exec['rebuild_nsd_config'],
        owner   => root,
        group   => 0,
        recurse => true,
        purge   => true,
        force   => true,
        ignore  => '*.yaml';
    }
  }
  include ::ibox::lib::dns_utils
}

# conntrackd wrapper
# only an internal calls hence referring
# to the types class
class ib_conntrackd::hafw(
  $conntrackd_interface = $ibox::types::hafw::conntrackd_interface,
  $conntrackd_destip    = $ibox::types::hafw::conntrackd_destip,
){
  class{'::conntrackd::config':
    protocol      => 'UDP',
    sync_mode     => 'ALARM',
    interface     => $conntrackd_interface,
    ipv4_address  => getvar("ipaddress_${conntrackd_interface}"),
    udp_ipv4_dest => $conntrackd_destip,
    before        => Service['keepalived'],
  }
  file{'/usr/local/sbin/conntrackd-primary-backup.sh':
    source  => '/usr/share/doc/conntrack-tools-1.4.2/doc/sync/primary-backup.sh',
    require => Package['conntrack-tools'],
    owner   => root,
    group   => 0,
    mode    => '0700';
  }
}

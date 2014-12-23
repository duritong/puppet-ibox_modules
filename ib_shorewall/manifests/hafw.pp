# manage a ha fw cluster
# only an internal calls hence referring
# to the types class
#
# Zones:
#   - net:  external network
#   - loc:  the dmz
#   - sync: sync network for conntrack
#   - fw:   the firewall itself
class ib_shorewall::hafw(
  $out_interface          = $ibox::types::hafw::out_interface,
  $in_interface           = $ibox::types::hafw::in_interface,
  $conntrackd_interface   = $ibox::types::hafw::conntrackd_interface,
  $net_in_rules           = $ibox::types::hafw::net_in_rules,
) {

  shorewall::zone{
    ['loc', 'sync' ]:
      type => 'ipv4';
  }

  shorewall::interface{
    $in_interface:
      zone    => 'loc',
      options => 'tcpflags,blacklist,nosmurfs,logmartians,routeback';
    $conntrackd_interface:
      zone    => 'sync',
      options => 'tcpflags,blacklist,nosmurfs,logmartians';
  }

  shorewall::policy{
    'net-to-loc':
      sourcezone      => 'net',
      destinationzone => 'loc',
      policy          => 'DROP',
      order           => 130;
    # reflect on failover
    'net-to-net':
      sourcezone      => 'net',
      destinationzone => 'net',
      policy          => 'ACCEPT',
      order           => 130;
    'loc-to-net':
      sourcezone      => 'loc',
      destinationzone => 'net',
      policy          => 'ACCEPT',
      order           => 130;
    # reflect on failover
    'loc-to-loc':
      sourcezone      => 'loc',
      destinationzone => 'loc',
      policy          => 'ACCEPT',
      order           => 130;
    'fw-to-loc':
      sourcezone      => '$FW',
      destinationzone => 'loc',
      policy          => 'ACCEPT',
      order           => 140;
    'fw-to-sync':
      sourcezone      => '$FW',
      destinationzone => 'sync',
      policy          => 'ACCEPT',
      order           => 140;
    'loc-to-fw':
      sourcezone      => 'loc',
      destinationzone => '$FW',
      shloglevel      => '$LOG',
      policy          => 'DROP',
      order           => 150;
    'sync-to-fw':
      sourcezone      => 'sync',
      destinationzone => '$FW',
      shloglevel      => '$LOG',
      policy          => 'REJECT',
      order           => 150;
  }
  shorewall::rule {
    'NewNotSyn-drop-net-loc':
      source          => 'net',
      destination     => 'loc',
      proto           => 'tcp',
      order           => 130,
      action          => 'dropNotSyn';
    'Silently-Handle-common-probes_icmp':
      source          => 'net',
      destination     => 'loc',
      proto           => 'icmp',
      destinationport => '8',
      order           => 800,
      action          => 'DROP';
    'loc-me-tcp_ssh':
      source          => 'loc',
      destination     => '$FW',
      proto           => 'tcp',
      destinationport => '22',
      order           => 240,
      action          => 'ACCEPT';
    'sync-me-tcp_ssh_sync':
      source          => 'sync',
      destination     => '$FW',
      proto           => 'tcp',
      destinationport => '22',
      order           => 240,
      action          => 'ACCEPT';
    'sync-me-vrrp':
      source          => 'sync',
      destination     => '$FW',
      proto           => 'vrrp',
      order           => 250,
      action          => 'ACCEPT';
    'sync-me-conntrackd':
      source          => 'sync',
      destination     => '$FW',
      proto           => 'udp',
      destinationport => '3780',
      order           => 250,
      action          => 'ACCEPT';
  }
  create_resources('ib_shorewall::hafw::net_in_rule', $net_in_rules)
}

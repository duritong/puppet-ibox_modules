# manage a ha fw cluster
class ib_shorewall::hafw(
  $out_interface,
  $out_ipaddress,
  $auth_pass,
  $in_interface,
  $in_ipaddress,
  $conntrackd_interface,
  $conntrackd_destip,
  $net_in_rules         = {},
  $is_master            = true,
) {

  if $is_master {
    $state = 'MASTER'
    $priority = '101'
  } else {
    $state = 'BACKUP'
    $priority = '100'
  }

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
    'loc-to-net':
      sourcezone      => 'loc',
      destinationzone => 'net',
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

  class{'conntrackd::config':
    protocol      => 'UDP',
    sync_mode     => 'ALARM',
    interface     => $conntrackd_interface,
    ipv4_address  => getvar("ipaddress_${conntrackd_interface}"),
    udp_ipv4_dest => $conntrackd_destip,
    before        => Service['keepalived'],
  }

  file{'/etc/conntrackd/primary-backup.sh':
    source  => '/usr/share/doc/conntrack-tools-1.4.2/doc/sync/primary-backup.sh',
    require => Package['conntrack-tools'],
    owner   => root,
    group   => 0,
    mode    => '0700';
  }
  #https://bugs.launchpad.net/tripleo/+bug/1342872
  selboolean{'domain_kernel_load_modules':
    persistent => true,
    value      => 'on',
    before     => Service['keepalived'],
  }
  include keepalived
  selinux::policy{'ib_keepalived':
    te_source => 'puppet:///modules/ib_keepalived/selinux/ib_keepalived.te',
    before    => Service['keepalived'],
  }
  #class{'keepalived::global_defs':
  #  notification_email => "root@${::fqdn}",
  #}
  $track_interface = reject(reject(
    split($::interfaces,','),
      $conntrackd_interface),'lo')

  keepalived::vrrp::instance { 'VI_50':
    interface             => $conntrackd_interface,
    state                 => $state,
    virtual_router_id     => '50',
    priority              => $priority,
    auth_type             => 'PASS',
    auth_pass             => $auth_pass,
    virtual_ipaddress     => [
     ## out
     #{
     #  ip  => $out_ipaddress,
     #  dev => $out_interface,
     #},
      # in
      {
        ip  => $in_ipaddress,
        dev => $in_interface,
      },
    ],
    track_interface       => $track_interface,
    notify_script_master  => '"/etc/conntrackd/primary-backup.sh primary"',
    notify_script_backup  => '"/etc/conntrackd/primary-backup.sh backup"',
    notify_script_fault   => '"/etc/conntrackd/primary-backup.sh fault"',
    #smtp_alert            => true,
  }
}

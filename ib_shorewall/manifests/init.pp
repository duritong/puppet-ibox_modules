# our basic shorewall setup
class ib_shorewall(
  $main_interface  = $::virtual ? {
    'virtualbox' => 'enp0s3',
    default      => 'eth0',
  },
  $rfc1918_maineth = true,
) {
  if ($operatingsystem == 'CentOS') and (versioncmp($::operatingsystemmajrelease,'7') < 0) {
    $conf_source = [
      "puppet:///modules/ib_shorewall/${::fqdn}/shorewall.conf",
      "puppet:///modules/ib_shorewall/shorewall.conf.${::operatingsystem}.${::operatingsystemmajrelease}",
      "puppet:///modules/ib_shorewall/shorewall.conf.${::operatingsystem}",
      'puppet:///modules/ib_shorewall/shorewall.conf',
    ]
  } else {
    $conf_source = false
  }
  class{'shorewall':
    conf_source => $conf_source,
    params      => hiera_hash('shorewall::params',{}),
  }

  shorewall::params {
    'LOG':
      value => 'info';
  }
  shorewall::zone {'net':
    type => 'ipv4';
  }

  shorewall::rule_section { 'NEW':
    order => 100;
  }

  shorewall::interface {$main_interface:
    zone    => 'net',
    rfc1918 => $rfc1918_maineth,
    options => 'tcpflags,blacklist,nosmurfs';
  }

  shorewall::policy {
    'fw-to-fw':
      sourcezone      => '$FW',
      destinationzone => '$FW',
      policy          => 'ACCEPT',
      order           => 100;
    'fw-to-net':
      sourcezone      => '$FW',
      destinationzone => 'net',
      policy          => 'DROP',
      shloglevel      => '$LOG',
      order           => 110;
    'net-to-fw':
      sourcezone      => 'net',
      destinationzone => '$FW',
      policy          => 'DROP',
      shloglevel      => '$LOG',
      order           => 120;
    'all-to-all':
      sourcezone      => 'all',
      destinationzone => 'all',
      policy          => 'REJECT',
      shloglevel      => '$LOG',
      order           => 900;
  }

  shorewall::rule {
    'Stop-NETBIOS-crap-tcp':
      source          => 'all',
      destination     => 'all',
      proto           => 'tcp',
      destinationport => '137,445',
      order           => 101,
      action          => 'REJECT';
    'Stop-NETBIOS-crap-udp':
      source          => 'all',
      destination     => 'all',
      proto           => 'udp',
      destinationport => '137:139',
      order           => 110,
      action          => 'REJECT';
    'NewNotSyn-drop-net-fw':
      source          => 'net',
      destination     => '$FW',
      proto           => 'tcp',
      order           => 120,
      action          => 'dropNotSyn';
    'traceroute':
      source          => 'net',
      destination     => '$FW',
      order           => 200,
      action          => 'Trcrt/ACCEPT';
    'ping':
      source          => 'all',
      destination     => 'all',
      order           => 201,
      action          => 'Ping/ACCEPT';
    'other_useful_icmp_0':
      source          => 'all',
      destination     => 'all',
      proto           => 'icmp',
      destinationport => '0/0',
      order           => 201,
      action          => 'AllowICMPs/ACCEPT';
    'other_useful_icmp_3':
      source          => 'all',
      destination     => 'all',
      proto           => 'icmp',
      destinationport => '3',
      order           => 201,
      action          => 'AllowICMPs/ACCEPT';
    'other_useful_icmp_3_4':
      source          => 'all',
      destination     => 'all',
      proto           => 'icmp',
      destinationport => '3/4',
      order           => 201,
      action          => 'AllowICMPs/ACCEPT';
    'other_useful_icmp_8':
      source          => 'all',
      destination     => 'all',
      proto           => 'icmp',
      destinationport => '8/0',
      order           => 201,
      action          => 'AllowICMPs/ACCEPT';
    'other_useful_icmp_11':
      source          => 'all',
      destination     => 'all',
      proto           => 'icmp',
      destinationport => '11',
      order           => 201,
      action          => 'AllowICMPs/ACCEPT';
    'other_useful_icmp_11_0':
      source          => 'all',
      destination     => 'all',
      proto           => 'icmp',
      destinationport => '11/0',
      order           => 201,
      action          => 'AllowICMPs/ACCEPT';
    'other_useful_icmp_11_1':
      source          => 'all',
      destination     => 'all',
      proto           => 'icmp',
      destinationport => '11/1',
      order           => 201,
      action          => 'AllowICMPs/ACCEPT';
    'allicmp-drop':
      source          => 'all',
      destination     => 'all',
      order           => 220,
      proto           => 'icmp',
      action          => 'DROP';
    'me-net-tcp_dns':
      source          => '$FW',
      destination     => 'net',
      proto           => 'tcp',
      destinationport => '53',
      order           => 250,
      action          => 'ACCEPT';
    'me-net-udp_dns':
      source          => '$FW',
      destination     => 'net',
      proto           => 'udp',
      destinationport => '53',
      order           => 251,
      action          => 'ACCEPT';
    # web is also needed for yum
    'me-net-defaultweb_tcp':
      source          => '$FW',
      destination     => 'net',
      proto           => 'tcp',
      destinationport => 'http,https',
      order           => 330,
      action          => 'ACCEPT';
  }

  if ($::operatingsystem in ['RedHat','CentOS']) and versioncmp($::operatingsystemmajrelease,'6') > 0{
    service{'firewalld':
      ensure => stopped,
      enable => false,
      before => Service['shorewall'],
    }
  }
}

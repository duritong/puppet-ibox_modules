# raise value for connection tracking
class ib_sysctl::nf_conntrack(
  max      => 65536,
  hashsize => 65536, 
) {

  $ip_conntrack_max_key = $::osfamily ? {
    RedHat => $::operatingsystemmajrelease ? {
      '5'     => 'net.ipv4.netfilter.ip_conntrack_max',
      default => 'net.netfilter.nf_conntrack_max',
    }
    default => 'net.ipv4.netfilter.ip_conntrack_max',
  }

  sysctl::value{'netfilter.ip_conntrack_max':
    key   => $ip_conntrack_max_key,
    value => $max,
  }

  $conntrack_hashsize_file = $::osfamily ? {
    RedHat => $::operatingsystemmajrelease ? {
      '5' => '/sys/module/ip_conntrack/parameters/hashsize',
      default => '/sys/module/nf_conntrack/parameters/hashsize'
    },
    default => '/sys/module/nf_conntrack/parameters/hashsize'
  }

  exec{"echo ${conntrack_hashsize_value} > ${conntrack_hashsize_file}":
    unless => "grep -q ${conntrack_hashsize_value} ${conntrack_hashsize_file}",
  }

}

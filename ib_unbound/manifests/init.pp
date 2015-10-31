# an unbound configuration
class ib_unbound(
  $local_data_source = undef,
  $test_domain       = 'nic.ch',
) {

  if $ibox::use_nagios {
    $nagios_test_domain = $test_domain
  } else {
    $nagios_test_domain = undef
  }

  class{'unbound':
    interface          => hiera('unbound::interface',$::ipaddress_eth0_1),
    manage_shorewall   => $ibox::use_shorewall,
    manage_munin       => $ibox::use_munin,
    nagios_test_domain => $nagios_test_domain,
    local_data_source  => $local_data_source,
  }

  include ::ibox::lib::dns_utils
}

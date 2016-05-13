# a HA firewall type
class ibox::types::hafw(
  $out_interface,
  $out_ipaddress,
  $in_interface,
  $in_ipaddress,
  $conntrackd_interface,
  $conntrackd_destips,
  $auth_password        = false,
  $in_ip6address        = 'fe80::1/64',
  $net_in_rules         = {},
) {
  if has_ip_address($conntrackd_destips[0]) {
    $conntrackd_destip = $conntrackd_destips[1]
    $is_master = true
  } else {
    $conntrackd_destip = $conntrackd_destips[0]
    $is_master = false
  }

  if !$auth_password {
    # only the first 8 characters are used by keepalived
    $auth_pass = trocla("ibox::types::hafw::auth_password_${::icluster_name}",'plain','length: 8')
  } else {
    $auth_pass = $auth_password
  }

  include ::ib_conntrackd::hafw
  include ::ib_keepalived::hafw
  include ::ib_shorewall::hafw
  include ::ibox::lib::firewall

  if $ibox::use_munin {
    include ::ib_munin::plugins::firewall::with_conntrack
  }
}

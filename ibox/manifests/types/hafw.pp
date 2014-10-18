# a HA firewall type
class ibox::types::hafw(
  $out_interface,
  $out_ipaddress,
  $auth_pass,
  $in_interface,
  $in_ipaddress,
  $conntrackd_interface,
  $conntrackd_destips,
  $net_in_rules         = {},
  $is_master            = true,
) {
  include ibox

  if has_ip_address($conntrackd_destips[0]) {
    $conntrackd_destip = $conntrackd_destips[1]
  } else {
    $conntrackd_destip = $conntrackd_destips[0]
  }

  include ib_conntrackd::hafw
  include ib_keepalived::hafw
  include ib_shorewall::hafw
}

# a HA firewall type
class ibox::types::hafw(
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
  include ib_conntrackd::hafw
  include ib_keepalived::hafw
  include ib_shorewall::hafw
}

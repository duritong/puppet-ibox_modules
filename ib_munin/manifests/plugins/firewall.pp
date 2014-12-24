# a few interesting graphs for a firewall
class ib_munin::plugins::firewall {
  munin::plugin {
    [ 'fw_conntrack', 'fw_forwarded_local' ]:
      config  => 'group root';
    [ 'fw_packets' ]:;
  }
  # https://github.com/hrix/munin-plugin-ip_conntrack
  munin::plugin::deploy{
    'ip_conntrack':
      source => 'ib_munin/plugins/ip_conntrack';
  }
}

# a few interesting graphs for a firewall
class ib_munin::plugins::firewall::with_conntrack inherits ib_munin::plugins::firewall {
  Munin::Plugin[ 'fw_conntrack','fw_forwarded_local']{
    config  => ['user root','group root']
  }
}

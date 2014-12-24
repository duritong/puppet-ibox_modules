# tools for firewalls
class ibox::lib::firewall {
  ensure_packages([
    'tcpdump',
    'iptraf-ng',
    'iptstate',
    ])
}

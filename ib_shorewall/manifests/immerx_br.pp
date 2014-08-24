# bridged hypervisors
class ib_shorewall::immerx_br inherits ib_shorewall {
  ## bridge zone
  shorewall::zone {
    'br':  type  =>      'ipv4';
  }

  # add routeback to internal bridged interface
  # http://www.shorewall.net/SimpleBridge.html
  Shorewall::Interface[$ib_shorewall::shorewall_main_interface]{
    options => 'tcpflags,blacklist,nosmurfs,routeback',
  }

  ## policy
  # http://www.shorewall.net/XenMyWay.html#Firewall
  shorewall::policy {
    'br-to-br':
      sourcezone      =>      'br',
      destinationzone =>      'br',
      policy          =>      'ACCEPT',
      order           =>      130;
  }
}

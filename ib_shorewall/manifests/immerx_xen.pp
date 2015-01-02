# firewall for xen hypervisors
class ib_shorewall::immerx_xen inherits ib_shorewall::immerx_br {
  ## base interface
  shorewall::interface { 'xenbr0':
    broadcast => '-',
    zone      =>  'br',
    options   =>  'routeback';
  }

  if ($::lsbdistcodename == 'wheezy') and ($::virtual == 'xen0') {
    # somehow this is also needed on xen
    shorewall::interface { 'xenbr1':
      broadcast => '-',
      zone      =>  'net',
      rfc1918   => true,
      options   =>  'routeback,tcpflags,blacklist,nosmurfs';
    }
  }
}

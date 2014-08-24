# kvm hypervisors
class ib_shorewall::immerx_kvm inherits ib_shorewall::immerx_br {
  ## base interface
  shorewall::interface { 'br0':
    broadcast => '-',
    zone    =>  'br',
    options =>  'routeback';
  }
}


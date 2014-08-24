# shorewall for hypervisors
class ib_shorewall::immerx {
  if $::virtual == 'xen0' {
    # only needed on debian
    case $::operatingsystem {
      debian: { include ib_shorewall::immerx_xen }
    }
  } elsif $ibox::is_kvm {
    include ib_shorewall::immerx_kvm
  }
}

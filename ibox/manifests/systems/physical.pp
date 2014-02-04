# things for physical setups
class ibox::systems::physical {
  include smartd

  case $::kernel {
    linux: {
      if $ibox::use_munin {
        include ib_munin::disks::physical
      }
      include mdadm::mismatch_cnt
    }
  }

  if $ibox::is_kvm {
    include ibox::systems::kvm_host
  }
}

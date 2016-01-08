# things for physical setups
class ibox::systems::physical {
  if $::lsbdistid != 'Raspbian' {
    include ::smartd
  }

  if $::kernel == 'Linux' {
    if $ibox::use_munin {
      include ::ib_munin::disks::physical
    }
    include ::mdadm::mismatch_cnt
  }

  if $ibox::is_kvm {
    include ::ibox::systems::kvm_host
  }
}

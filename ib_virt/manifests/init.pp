# manage virt stuff
class ib_virt {
  include virt

  if $ibox::is_kvm {
    include virt::kvm
    # kvm hosts should not swap
    # http://pic.dhe.ibm.com/infocenter/lnxinfo/v3r0m0/topic/liaat/liaattunsetswapiness.htm
    sysctl::value{
      'vm.swappiness':
        value => 0;
    }
  }
}

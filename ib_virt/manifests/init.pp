# manage virt stuff
class ib_virt(
  $is_kvm = false,
){
  include virt

  if $is_kvm {
    include virt::kvm
    # kvm hosts should not swap
    # http://pic.dhe.ibm.com/infocenter/lnxinfo/v3r0m0/topic/liaat/liaattunsetswapiness.htm
    sysctl::value{
      'vm.swappiness':
        value => 0;
    }
  }
}

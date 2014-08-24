# all the configs for your ibox
class ibox(
  $use_munin      = false,
  $use_shorewall  = false,
  $is_kvm         = false,
) {

  include ibox::systems::base

  case $::kernel {
    linux: { include ibox::systems::linux }
    openbsd: { include ibox::systems::openbsd }
    default: { fail('Not supported kernel') }
  }
  case $::osfamily {
    redhat: { include ibox::systems::redhat }
    debian,ubuntu: { include ibox::systems::debian }
    default: { } # do nothing
  }

  include ib_virt
  case $::virtual {
    'xen0': { include ibox::systems::xen0 }
    default: {
      # do nothing
    }
  }
  if str2bool($::is_virtual) {
    include ibox::systems::guests
  } else {
    include ibox::systems::physical
  }

}

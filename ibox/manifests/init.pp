# all the configs for your ibox
class ibox(
  $use_munin     = false,
  $use_shorewall = false,
) {

  include ibox::systems::base

  case $::kernel {
    linux: { include ibox::systems::linux }
    openbsd: { include ibox::systems::openbsd }
    default: { fail('Not supported kernel') }
  }
  case $::osfamily {
    redhat: { include ibox::systems::redhat }
    default: { } # do nothing
  }

  include ib_virt
  case $::virtual {
    'xen0': { include ibox::systems::xen0 }
    default: {
      # do nothing
    }   
  }
  case $::virtual {
    'xen0','physical': { include ibox::systems::physical }
    'xenu': { include ibox::systems::xenu }
    default: {
      # do nothing
    }   
  }

}

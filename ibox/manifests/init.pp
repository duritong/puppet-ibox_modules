# all the configs for your ibox
class ibox(
  $use_munin      = false,
  $use_nagios     = false,
  $use_shorewall  = false,
  $is_kvm         = false,
  $types          = [],
  $root_password  = false,
) {

  $root_keys = hiera_hash('ibox::root_keys',{})
  include ::ibox::systems::base

  case $::kernel {
    'Linux': { include ::ibox::systems::linux }
    default: { fail('Not supported kernel') }
  }
  case $::osfamily {
    'RedHat': { include ::ibox::systems::redhat }
    'Debian','Ubuntu': { include ::ibox::systems::debian }
    default: { } # do nothing
  }

  include ::ib_virt
  case $::virtual {
    'xen0': { include ::ibox::systems::xen0 }
    default: {
      # do nothing
    }
  }
  if str2bool($::is_virtual) {
    include ::ibox::systems::guests
  } else {
    include ::ibox::systems::physical
  }

  if !empty($types) {
    include prefix($types,'::ibox::types::')
  }

  # this must be after the types
  $use_exim = hiera('ibox::systems::mail::use_exim',false)
  if !$use_exim {
    include ::ibox::systems::mail
  } elsif $use_exim != true {
    include "::ib_exim::${use_exim}"
  }
}

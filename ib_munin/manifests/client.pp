# our munin-node configuration
class ib_munin::client {
  class{'munin::client':
    manage_shorewall           => hiera('munin::client::manage_shorewall',$ibox::use_shorewall),
  }
  # we do that only for EL6
  if str2bool($::selinux) and ($::operatingsystemmajrelease == 6) {
    selinux::policy{
      'ibox-munin':
        te_source => 'puppet:///modules/ib_selinux/policies/ibox-munin/ibox-munin.te',
        require   => Package['munin-node'],
        before    => Service['munin-node'],
    }
  }
}

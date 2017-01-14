# disk setup for a munin host
class ib_disks::datavgs::muninhost(
  $size_lib = '3G',
) {

  disks::lv_mount{
    'munin_liblv':
      folder  => '/var/lib/munin',
      size    => $size_lib,
      owner   => 'munin',
      group   => 'munin',
      require => Package['munin-node'];
  }
}

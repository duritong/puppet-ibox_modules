# disk setup for a munin host
class ib_disks::muninhost(
  $size_lib = '3G',
  $size_tmp = '2G',
) {

  disks::lv_mount{
    'munin_liblv':
      folder        => '/var/lib/munin',
      size          => $size_lib,
      before        => Package['munin-node'];
    'munin_tmplv':
      folder        => '/var/tmp/munin-cgi-graph',
      size          => $size_tmp,
      before        => Package['munin-node'];
  } -> file{'/var/lib/munin/plugin-state':
    ensure  => directory,
    seltype => 'munin_plugin_state_t',
    owner   => root,
    group   => munin,
    mode    => '0664';
  }
}

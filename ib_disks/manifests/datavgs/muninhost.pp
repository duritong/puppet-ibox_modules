# disk setup for a munin host
class ib_disks::datavg::muninhost(
  $size_lib = '3G',
  $size_tmp = '2G',
) {

  disks::lv_mount{
    'munin_liblv':
      folder  => '/var/lib/munin',
      size    => $size_lib,
      owner   => 'munin',
      group   => 'munin',
      require => Package['munin-node'];
    'munin_tmplv':
      folder  => '/var/tmp/munin-cgi-graph',
      size    => $size_tmp,
      owner   => 'apache',
      group   => 'apache',
      seltype => 'httpd_munin_rw_content_t',
      require => Package['apache'];
  } -> file{'/var/lib/munin/plugin-state':
    ensure  => directory,
    seltype => 'munin_plugin_state_t',
    owner   => root,
    group   => munin,
    mode    => '0664';
  }
}

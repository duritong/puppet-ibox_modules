# setup for our munin host
class ib_munin::host(
  $header_source = 'puppet:///modules/ib_munin/config/munin.conf.header',
) {
  include mod_fcgid
  class{'munin::host':
    header_source => $header_source,
  }
  include ib_disks::muninhost

  file{
    '/etc/httpd/conf.d/munin.conf':
      ensure  => absent,
      require => Package['munin'],
      notify  => Service['apache'];
  }

  if $::operatingsystemmajrelease == 6 {
    selinux::policy{
      'ibox-munin-fcgi':
        te_source => 'puppet:///modules/ib_selinux/policies/ibox-munin-fcgi/ibox-munin-fcgi.te',
        require   => Package['munin'],
        before    => Service['httpd'],
    }
  }
}

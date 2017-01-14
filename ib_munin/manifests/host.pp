# setup for our munin host
class ib_munin::host(
  $header_source = 'puppet:///modules/ib_munin/config/host/munin.conf.header',
) {
  include ::mod_fcgid
  class{'::munin::host':
    header_source    => $header_source,
    manage_shorewall => $ibox::use_shorewall,
  }
  include ::ib_disks::datavgs::muninhost

  file{
    '/etc/httpd/conf.d/munin.conf':
      ensure  => absent,
      require => Package['munin'],
      notify  => Service['apache'];
    '/var/lib/munin/plugin-state':
      ensure  => directory,
      seltype => 'munin_plugin_state_t',
      require => Package['munin'],
      owner   => root,
      group   => munin,
      mode    => '0664';
    [ '/var/lib/munin/cgi-tmp','/var/lib/munin/cgi-tmp/munin-cgi-graph']:
      ensure  => directory,
      seltype => 'httpd_munin_rw_content_t',
      require => Package['munin'],
      before  => Service['apache'],
      owner   => apache,
      group   => apache,
      mode    => '0600';
  }
  if $::operatingsystemmajrelease == 6 {
    selinux::fcontext{
      '/var/lib/munin/plugin-state':
        setype => 'munin_plugin_state_t';
      '/var/lib/munin/cgi-tmp':
        setype => 'httpd_munin_rw_content_t';
    }
    selinux::policy{
      'ibox-munin-fcgi':
        te_source => 'puppet:///modules/ib_selinux/policies/ibox-munin-fcgi/ibox-munin-fcgi.te',
        require   => Package['munin'],
        before    => Service['httpd'],
    }
  }
}

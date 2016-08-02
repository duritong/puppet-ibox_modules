# be sure to put logs on an own fs
class ib_nginx {
  include ::ib_disks::datavgs::nginx
  class{'::nginx':
    manage_shorewall_http  => $ibox::use_shorewall,
    manage_shorewall_https => $ibox::use_shorewall,
    use_munin              => $ibox::use_munin,
  }

  certs::dhparams{
    '/etc/pki/tls/certs/dhparams.pem':
      before => Service['nginx'],
  }
}

# so that exim can read our internal certs
class ib_certs::exim inherits ib_certs {
  $group = $::osfamily ? {
    'Debian' => 'Debian-exim',
    default  => 'exim',
  }
  File['/etc/pki/tls/certs/localhost.crt','/etc/pki/tls/private/localhost.key']{
    group => $group,
    mode  => '0640',
  }
}

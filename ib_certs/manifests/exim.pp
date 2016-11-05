# so that exim can read our internal certs
class ib_certs::exim inherits ib_certs {
  $group = $::osfamily ? {
    'Debian' => 'Debian-exim',
    default  => 'exim',
  }
  File[$ib_certs::key_name]{
    group => $group,
    mode  => '0640',
  }
}

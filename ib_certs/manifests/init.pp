# generate and deploy a default internal ca,
# a default key that is signed by our ca and
# also manage custom CAs
class ib_certs {
  include ::trocla::ca::params
  certs::manage_custom_cacert{
    'main':
      content => trocla('ca_main','x509',$trocla::ca::params::ca_options);
  }
  $options = {
    profiles => ['x509auto'],
    'CN'     => $::fqdn,
    'ca'     => 'ca_main',
  }

  $cert_content = trocla("main_cert_${::fqdn}",'x509',merge($options,{ render => { certonly => true } }))
  $key_content  = trocla("main_cert_${::fqdn}",'x509',merge($options,{ render => { keyonly => true } }))
  if $::osfamily == 'Debian' {
    $cert_name = '/etc/ssl/localcerts/localhost.crt'
    $key_name  = '/etc/ssl/localcerts/localhost.key'
  } else {
    $cert_name = '/etc/pki/tls/certs/localhost.crt'
    $key_name  = '/etc/pki/tls/private/localhost.key'
  }
  file{
    $cert_name:
      content => $cert_content,
      owner   => root,
      group   => 0,
      mode    => '0644';
    $key_name:
      content => $key_content,
      owner   => root,
      group   => 0,
      mode    => '0600';
  }
  if $::osfamily == 'Debian' {
    file{'/etc/ssl/localcerts':
      ensure => directory,
      owner   => root,
      group   => 0,
      mode    => '0644';
    }
  }

  include ::ib_certs::custom_cas
}


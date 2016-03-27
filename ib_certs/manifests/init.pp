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
  file{
    '/etc/pki/tls/certs/localhost.crt':
      content => $cert_content,
      owner   => root,
      group   => 0,
      mode    => '0600';
    '/etc/pki/tls/private/localhost.key':
      content => $key_content,
      owner   => root,
      group   => 0,
      mode    => '0600';
  }

  include ::ib_certs::custom_cas
}


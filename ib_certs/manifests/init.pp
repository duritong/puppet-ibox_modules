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
      mode    => '0644';
    '/etc/pki/tls/private/localhost.key':
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
    File['/etc/pki/tls/certs/localhost.crt']{
      path => '/etc/ssl/localcerts/localhost.crt'
    }
    File['/etc/pki/tls/private/localhost.key']{
      path => '/etc/ssl/localcerts/localhost.key'
    }
  }

  include ::ib_certs::custom_cas
}


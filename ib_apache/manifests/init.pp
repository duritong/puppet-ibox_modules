# manage all aspects of an apache
class ib_apache(
  $worker                           = true,
  $backend                          = false,
  $manage_disks                     = true,
  $default_ssl_certificate_file     = '/etc/pki/tls/certs/localhost.crt',
  $default_ssl_certificate_key_file = '/etc/pki/tls/private/localhost.key',
){

  include ::certs::ssl_config
  # EL5 doesn't yet fully support tls12
  if $backend and versioncmp($::operatingsystemmajrelease,'5') > 0 {
    $ssl_cipher_suite = $certs::ssl_config::ciphers_tls12
  } else {
    $ssl_cipher_suite = $certs::ssl_config::ciphers
  }
  class{'::apache':
    manage_shorewall                 => $ibox::use_shorewall,
    manage_munin                     => $ibox::use_munin,
    default_ssl_certificate_file     => $default_ssl_certificate_file,
    default_ssl_certificate_key_file => $default_ssl_certificate_key_file,
    ssl_cipher_suite                 => $ssl_cipher_suite,
  }

  apache::config::global{
    'httpd_tuning.conf':
      source  => 'puppet:///modules/ib_apache/conf.d/httpd_tuning.conf';
    'default_ssl_cert.conf':
      content => template('ib_apache/conf.d/default_ssl_cert.conf.erb');
  }

  include ::apache::ssl
  include ::apache::noiplog
  include ::mod_removeip

  if $worker {
    # as we run fcgi we can run worker
    include ::apache::worker
  }

  apache::config::global{
    'unset_forwarded_for.conf':
      content => '<IfDefine !HttpdWithIPs>
  RequestHeader unset X-Forwarded-For
</IfDefine>
',
  }

  if str2bool($::selinux) {
    selboolean{
      [ 'httpd_enable_cgi',
        'httpd_can_sendmail', ]:
          value       => 'on',
          persistent  => true,
          require     => Package['apache'],
          before      => Service['apache'];
    }
  }
  if $manage_disks {
    include ::ib_disks::datavgs::www
  }
}

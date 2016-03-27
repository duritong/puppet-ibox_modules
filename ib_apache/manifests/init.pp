# manage all aspects of an apache
class ib_apache(
  $worker                           = true,
  $backend                          = false,
  $cluster_node                     = 'all',
  $default_ssl_certificate_file     = '/etc/pki/tls/certs/localhost.crt',
  $default_ssl_certificate_key_file = '/etc/pki/tls/private/localhost.key',
){

  include ::certs::ssl_config
  $ssl_cipher_suite = $backend ? {
    true    => $certs::ssl_config::ciphers_tls12,
    default => $certs::ssl_config::ciphers
  }
  class{'::apache':
    cluster_node                     => $cluster_node,
    manage_shorewall                 => $ibox::use_shorewall,
    manage_munin                     => $ibox::use_munin,
    default_ssl_certificate_file     => $default_ssl_certificate_file,
    default_ssl_certificate_key_file => $default_ssl_certificate_key_file,
    ssl_cipher_suite                 => $ssl_cipher_suite,
  }
  include ::apache::ssl
  include ::apache::noiplog
  include ::mod_removeip

  if $worker {
    # as we run fcgi we can run worker
    include ::apache::worker
  }

  apache::config::global{'unset_forwarded_for.conf':
    content => "<IfDefine !HttpdWithIPs>\n  RequestHeader unset X-Forwarded-For\n</IfDefine>\n",
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
}

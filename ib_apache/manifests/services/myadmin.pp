# manage php*admin installation
class ib_apache::services::myadmin(
  $myadmin_host               = undef,
  $myadmin_alias              = 'absent',
  $myadmin_monitor            = 'absent',
  $pgadmin_host               = undef,
  $pgadmin_alias              = 'absent',
  $pgadmin_monitor            = 'absent',
  $my_ssl_certificate_file       = '/etc/pki/tls/certs/localhost.crt',
  $my_ssl_certificate_key_file   = '/etc/pki/tls/private/localhost.key',
  $my_ssl_certificate_chain_file = false,
  $pg_ssl_certificate_file       = '/etc/pki/tls/certs/localhost.crt',
  $pg_ssl_certificate_key_file   = '/etc/pki/tls/private/localhost.key',
  $pg_ssl_certificate_chain_file = false,
) {
  if $myadmin_host {
    include ::ib_apache::webhosting_php
    phpmyadmin::vhost{$myadmin_host:
      domainalias   => $myadmin_alias,
      run_mode      => 'fcgid',
      run_uid       => iuid("${myadmin_host}_${::fqdn}",'webhosting'),
      run_gid       => iuid("${myadmin_host}_${::fqdn}",'webhosting'),
      monitor_url   => $myadmin_monitor,
      manage_nagios => $myadmin_monitor != 'absent',
      configuration => {
        ssl_certificate_file       => $my_ssl_certificate_file,
        ssl_certificate_key_file   => $my_ssl_certificate_key_file,
        ssl_certificate_chain_file => $my_ssl_certificate_chain_file,
      },
    }
  }
  if $pgadmin_host {
    include ::ib_apache::webhosting_php
    phppgadmin::vhost{$pgadmin_host:
      domainalias   => $pgadmin_alias,
      run_mode      => 'fcgid',
      run_uid       => iuid("${pgadmin_host}_${::fqdn}",'webhosting'),
      run_gid       => iuid("${pgadmin_host}_${::fqdn}",'webhosting'),
      monitor_url   => $pgadmin_monitor,
      manage_nagios => $pgadmin_monitor != 'absent',
      configuration => {
        ssl_certificate_file       => $pg_ssl_certificate_file,
        ssl_certificate_key_file   => $pg_ssl_certificate_key_file,
        ssl_certificate_chain_file => $pg_ssl_certificate_chain_file,
      },
    }
  }
}
